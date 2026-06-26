"""Reconcile the *unsorry Roadmap* GitHub Project from repo state (ADR-077 / SPEC-077-A).

GitHub Projects has no native notion of "files as items": a new ADR in
``docs/adrs/adrs.json`` — or a status flip ``Proposed`` → ``Accepted`` — never reaches
the board on its own (unlike a *linked issue*, whose open/closed state the board
mirrors live). This tool closes that gap. It reads the authoritative
``docs/adrs/adrs.json`` index and reconciles the board so every ADR is a draft item
carrying its literal status, and it tidies up the issue items that the built-in
*auto-add* workflow drops on with no custom fields set.

Reconcile rules
---------------
* **ADRs** (one draft item each, keyed by the ``ADR-NNN`` id in the title):
  - missing  → create the draft, set ``ADR Status`` + ``Item Type=ADR`` + ``ADR #``,
    and *seed* ``Roadmap Stage`` (``Pending`` → ``Backlog``, else ``Done``);
  - present  → enforce ``ADR Status`` (the source of truth — this is what carries a
    ``Proposed`` → ``Accepted`` flip onto the board), backfill ``Item Type`` / ``ADR #``,
    and refresh the title if the ADR was renamed.
* **Roadmap Stage is curated, never clobbered.** It is written *only* when an item is
  first created (or is empty). The maintainer's hand-triage of lanes is preserved on
  every subsequent sync.
* **Issue items** already on the board (added live or by auto-add): backfill
  ``Item Type=Issue``; a *closed* issue gets ``Roadmap Stage=Done``; an *open* issue
  with no stage is seeded ``Backlog`` — an open issue that already has a stage is left
  to the maintainer's triage.

Determinism / safety: ``--check`` computes the same plan as ``--sync`` but only reports
it (exit 1 on drift, 0 when clean); ``--sync`` applies it. Both are idempotent — a
second run with no repo change plans nothing. The board coordinates and the GraphQL
plumbing are the only I/O; all planning is pure and unit-tested.

Usage::

    python3 -m tools.project_sync --check [<repo-root>]   # report drift, exit 1 if any
    python3 -m tools.project_sync --sync  [<repo-root>]    # apply
    python3 -m tools.project_sync --plan  [<repo-root>]    # print the plan as JSON

Auth: shells out to ``gh api graphql``; in CI set ``GH_TOKEN`` to the ``PROJECTS_TOKEN``
secret (a PAT carrying the ``project`` scope). ``<repo-root>`` defaults to ``.``.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

# ── Board coordinates (env-overridable; field IDs are resolved by *name* at runtime,
#    never hard-coded, so a recreated project Just Works) ────────────────────────────
OWNER = os.environ.get("PROJECT_OWNER", "agenticsnz")
NUMBER = int(os.environ.get("PROJECT_NUMBER", "1"))

ADR_STATUS = "ADR Status"
STAGE = "Roadmap Stage"
ITEM_TYPE = "Item Type"
ADR_NUM = "ADR #"

REPO_BLOB = "https://github.com/agenticsnz/unsorry/blob/main/docs/adrs/"

# Identity is the ADR *file*, not its number: the corpus has two ``ADR-041`` files
# (adr_index warns about this), so the number is not a unique key. Each draft's body
# embeds a link to its file (see ``draft_body``); we recover it to match items.
_FILE_RE = re.compile(r"\[(ADR-[^\]]+?\.md)\]")


# ── Pure mapping / rendering (no I/O) ─────────────────────────────────────────────


def file_of(body: str) -> str | None:
    """The ``ADR-*.md`` filename a draft body links to, or ``None``."""
    m = _FILE_RE.search(body or "")
    return m.group(1) if m else None


def desired_adr_status(status: str) -> str:
    """Map a raw ADR ``status`` cell to the board's ``ADR Status`` option."""
    s = (status or "").lower()
    if "sponsor" in s:
        return "Sponsored"
    if s.startswith("proposed"):
        return "Pending"
    return "Accepted"


def seed_stage_for_adr(status: str) -> str:
    """Initial ``Roadmap Stage`` for a *new* ADR item (seed only — never re-applied)."""
    return "Backlog" if desired_adr_status(status) == "Pending" else "Done"


def draft_title(adr: dict) -> str:
    return f'{adr["id"]} — {adr["title"]}'


def draft_body(adr: dict) -> str:
    return (
        f'**Status:** {adr["status"]}  \n**Date:** {adr["date"]}  \n\n'
        f'[{adr["file"]}]({REPO_BLOB}{adr["file"]})'
    )


# ── Plan model ────────────────────────────────────────────────────────────────────


@dataclass
class Action:
    kind: str  # "create_adr" | "set_fields" | "set_title"
    label: str
    adr: dict | None = None
    item_id: str | None = None
    title: str | None = None
    # field name -> ("select", option_name) | ("number", int)
    sets: dict = field(default_factory=dict)

    def describe(self) -> str:
        if self.kind == "create_adr":
            return f"create draft {self.label}"
        if self.kind == "set_title":
            return f"retitle {self.label} → {self.title!r}"
        pretty = ", ".join(f"{k}={v[1]}" for k, v in self.sets.items())
        return f"set {self.label}: {pretty}"


@dataclass
class Item:
    """A board item as read back from the project (draft or linked issue)."""

    item_id: str
    kind: str  # "DraftIssue" | "Issue"
    title: str | None = None
    number: int | None = None
    state: str | None = None  # OPEN | CLOSED  (issues only)
    body: str | None = None  # draft body (carries the ADR file link)
    fields: dict = field(default_factory=dict)  # field name -> current value


# ── Pure planners ─────────────────────────────────────────────────────────────────


def plan_adrs(adrs: list[dict], by_file: dict[str, Item]) -> list[Action]:
    """Actions to reconcile every ADR; pure given the current board snapshot.

    ``by_file`` maps an ADR filename → its existing draft item (keyed by file, not
    number, so the duplicate ``ADR-041`` files stay distinct).
    """
    actions: list[Action] = []
    for adr in adrs:
        aid = adr["id"]
        want_status = desired_adr_status(adr["status"])
        item = by_file.get(adr["file"])
        if item is None:
            actions.append(
                Action(
                    kind="create_adr",
                    label=aid,
                    adr=adr,
                    sets={
                        ADR_STATUS: ("select", want_status),
                        STAGE: ("select", seed_stage_for_adr(adr["status"])),
                        ITEM_TYPE: ("select", "ADR"),
                        ADR_NUM: ("number", adr["number"]),
                    },
                )
            )
            continue
        sets: dict = {}
        if item.fields.get(ADR_STATUS) != want_status:
            sets[ADR_STATUS] = ("select", want_status)
        if item.fields.get(ITEM_TYPE) != "ADR":
            sets[ITEM_TYPE] = ("select", "ADR")
        if item.fields.get(ADR_NUM) != adr["number"]:
            sets[ADR_NUM] = ("number", adr["number"])
        # Roadmap Stage intentionally untouched on update (curated by the maintainer).
        if sets:
            actions.append(Action("set_fields", aid, item_id=item.item_id, sets=sets))
        want_title = draft_title(adr)
        if item.title != want_title:
            actions.append(
                Action("set_title", aid, item_id=item.item_id, title=want_title)
            )
    return actions


def plan_issues(issue_items: list[Item]) -> list[Action]:
    """Tidy up issue items (backfill type; closed→Done; seed empty open→Backlog)."""
    actions: list[Action] = []
    for it in issue_items:
        sets: dict = {}
        if it.fields.get(ITEM_TYPE) != "Issue":
            sets[ITEM_TYPE] = ("select", "Issue")
        stage = it.fields.get(STAGE)
        if it.state == "CLOSED" and stage != "Done":
            sets[STAGE] = ("select", "Done")
        elif it.state == "OPEN" and not stage:
            sets[STAGE] = ("select", "Backlog")
        if sets:
            actions.append(
                Action("set_fields", f"#{it.number}", item_id=it.item_id, sets=sets)
            )
    return actions


# ── GraphQL client (the only I/O) ─────────────────────────────────────────────────

_TRANSIENT = ("temporary conflict", "was modified", "secondary rate limit",
              "please try again", "rate limit")

_SCHEMA_Q = """
query($owner:String!,$number:Int!){
  organization(login:$owner){ projectV2(number:$number){ id
    fields(first:50){ nodes{
      __typename
      ... on ProjectV2FieldCommon{ id name }
      ... on ProjectV2SingleSelectField{ id name options{ id name } }
    }}
  }}
}
"""

_ITEMS_Q = """
query($owner:String!,$number:Int!,$cursor:String){
  organization(login:$owner){ projectV2(number:$number){
    items(first:100, after:$cursor){
      pageInfo{ hasNextPage endCursor }
      nodes{ id
        content{ __typename
          ... on Issue{ number url state }
          ... on DraftIssue{ title body } }
        fieldValues(first:30){ nodes{ __typename
          ... on ProjectV2ItemFieldSingleSelectValue{ name field{ ... on ProjectV2FieldCommon{ name } } }
          ... on ProjectV2ItemFieldNumberValue{ number field{ ... on ProjectV2FieldCommon{ name } } }
          ... on ProjectV2ItemFieldTextValue{ text field{ ... on ProjectV2FieldCommon{ name } } } } }
      }
    }
  }}
}
"""


class GraphQLError(RuntimeError):
    pass


class Client:
    """Thin wrapper over ``gh api graphql``. Resolves the project schema once."""

    def __init__(self, owner: str = OWNER, number: int = NUMBER, runner=None):
        self.owner, self.number = owner, number
        self._run = runner or self._gh
        self.project_id: str | None = None
        self.fields: dict[str, dict] = {}  # name -> {id, options:{name:id}}

    # -- transport -----------------------------------------------------------------
    @staticmethod
    def _gh(query: str, variables: dict) -> dict:
        cmd = ["gh", "api", "graphql", "-f", f"query={query}"]
        for k, v in variables.items():
            if v is None:
                continue
            flag = "-F" if isinstance(v, int) and not isinstance(v, bool) else "-f"
            cmd += [flag, f"{k}={v}"]
        last = ""
        for attempt in range(7):
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode == 0:
                out = json.loads(r.stdout)
                if "errors" not in out:
                    return out["data"]
                last = json.dumps(out["errors"])[:400]
            else:
                last = r.stderr.strip()[:400]
            if any(t in last.lower() for t in _TRANSIENT):
                time.sleep(0.6 * (2 ** attempt))
                continue
            raise GraphQLError(last)
        raise GraphQLError(f"after retries: {last}")

    # -- schema --------------------------------------------------------------------
    def load_schema(self) -> None:
        data = self._run(_SCHEMA_Q, {"owner": self.owner, "number": self.number})
        proj = data["organization"]["projectV2"]
        self.project_id = proj["id"]
        for f in proj["fields"]["nodes"]:
            if not f:
                continue
            self.fields[f["name"]] = {
                "id": f["id"],
                "options": {o["name"]: o["id"] for o in f.get("options", [])},
            }

    def _field_id(self, name: str) -> str:
        return self.fields[name]["id"]

    def _option_id(self, name: str, option: str) -> str:
        return self.fields[name]["options"][option]

    # -- read items ----------------------------------------------------------------
    def load_items(self) -> list[Item]:
        items: list[Item] = []
        cursor = None
        while True:
            data = self._run(
                _ITEMS_Q,
                {"owner": self.owner, "number": self.number, "cursor": cursor},
            )
            conn = data["organization"]["projectV2"]["items"]
            for node in conn["nodes"]:
                items.append(self._to_item(node))
            if conn["pageInfo"]["hasNextPage"]:
                cursor = conn["pageInfo"]["endCursor"]
            else:
                break
        return items

    @staticmethod
    def _to_item(node: dict) -> Item:
        content = node.get("content") or {}
        kind = content.get("__typename", "DraftIssue")
        fields: dict = {}
        for fv in node.get("fieldValues", {}).get("nodes", []):
            fname = (fv.get("field") or {}).get("name")
            if not fname:
                continue
            if "name" in fv:
                fields[fname] = fv["name"]
            elif "number" in fv:
                fields[fname] = fv["number"]
            elif "text" in fv:
                fields[fname] = fv["text"]
        return Item(
            item_id=node["id"],
            kind=kind,
            title=content.get("title"),
            number=content.get("number"),
            state=content.get("state"),
            body=content.get("body"),
            fields=fields,
        )

    # -- mutations -----------------------------------------------------------------
    def create_draft(self, title: str, body: str) -> str:
        q = ("mutation($p:ID!,$t:String!,$b:String!){addProjectV2DraftIssue("
             "input:{projectId:$p,title:$t,body:$b}){projectItem{id}}}")
        data = self._run(q, {"p": self.project_id, "t": title, "b": body})
        return data["addProjectV2DraftIssue"]["projectItem"]["id"]

    def set_title(self, item_id: str, title: str) -> None:
        q = ("mutation($i:ID!,$t:String!){updateProjectV2DraftIssue("
             "input:{draftIssueId:$i,title:$t}){draftIssue{id}}}")
        # The draft *issue* id differs from the *item* id; resolve via the item.
        self._run(q, {"i": self._draft_id(item_id), "t": title})

    def _draft_id(self, item_id: str) -> str:
        q = ("query($i:ID!){node(id:$i){... on ProjectV2Item{"
             "content{... on DraftIssue{id}}}}}")
        data = self._run(q, {"i": item_id})
        return data["node"]["content"]["id"]

    def apply_sets(self, item_id: str, sets: dict) -> None:
        """One batched mutation setting every field in ``sets`` on ``item_id``."""
        parts = []
        for n, (fname, (kind, val)) in enumerate(sets.items()):
            fid = self._field_id(fname)
            if kind == "select":
                lit = f'{{singleSelectOptionId:"{self._option_id(fname, val)}"}}'
            else:
                lit = f"{{number:{val}}}"
            parts.append(
                f"a{n}:updateProjectV2ItemFieldValue(input:{{projectId:$p,"
                f'itemId:$i,fieldId:"{fid}",value:{lit}}}){{clientMutationId}}'
            )
        q = "mutation($p:ID!,$i:ID!){" + " ".join(parts) + "}"
        self._run(q, {"p": self.project_id, "i": item_id})


# ── Orchestration ─────────────────────────────────────────────────────────────────


def load_adrs(root: Path) -> list[dict]:
    data = json.loads((root / "docs" / "adrs" / "adrs.json").read_text("utf-8"))
    return data["adrs"]


def build_plan(adrs: list[dict], items: list[Item]) -> list[Action]:
    by_file: dict[str, Item] = {}
    issue_items: list[Item] = []
    for it in items:
        if it.kind == "Issue":
            issue_items.append(it)
        else:
            f = file_of(it.body)
            if f:
                by_file[f] = it
    return plan_adrs(adrs, by_file) + plan_issues(issue_items)


def apply_plan(client: Client, plan: list[Action]) -> None:
    for a in plan:
        if a.kind == "create_adr":
            item_id = client.create_draft(draft_title(a.adr), draft_body(a.adr))
            client.apply_sets(item_id, a.sets)
        elif a.kind == "set_fields":
            client.apply_sets(a.item_id, a.sets)
        elif a.kind == "set_title":
            client.set_title(a.item_id, a.title)


def reconcile(root: Path, *, apply: bool, client: Client | None = None) -> list[Action]:
    client = client or Client()
    client.load_schema()
    plan = build_plan(load_adrs(root), client.load_items())
    if apply:
        apply_plan(client, plan)
    return plan


# ── CLI ───────────────────────────────────────────────────────────────────────────


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    flags = ("--check", "--sync", "--plan")
    modes = [f for f in flags if f in argv]
    if len(modes) != 1:
        print(f"exactly one of {', '.join(flags)} required", file=sys.stderr)
        return 2
    mode = modes[0]
    rest = [a for a in argv if a not in flags]
    root = Path(rest[0]) if rest else Path(".")

    try:
        plan = reconcile(root, apply=(mode == "--sync"))
    except GraphQLError as e:
        print(f"::warning::project-sync could not reach the board: {e}", file=sys.stderr)
        return 0  # degrade gracefully (e.g. PROJECTS_TOKEN unset / API blip)

    if mode == "--plan":
        print(json.dumps([{"kind": a.kind, "label": a.label,
                           "desc": a.describe()} for a in plan], indent=2))
        return 0
    if mode == "--sync":
        print(f"project-sync: applied {len(plan)} action(s)")
        for a in plan:
            print(f"  · {a.describe()}")
        return 0
    # --check
    if plan:
        print(f"project board drift: {len(plan)} pending action(s):", file=sys.stderr)
        for a in plan:
            print(f"  · {a.describe()}", file=sys.stderr)
        return 1
    print("project board in sync")
    return 0
