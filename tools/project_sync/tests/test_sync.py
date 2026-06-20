"""project-sync tests (ADR-077 / SPEC-077-A).

Pure unit tests over the mapping/planning functions, plus an end-to-end reconcile
against an in-memory fake board that records mutations — proving idempotency and the
"never clobber Roadmap Stage" rule. No network, no real project, no ``gh``.
"""
from __future__ import annotations

import json
from pathlib import Path

from tools.project_sync import sync
from tools.project_sync.sync import (
    ADR_NUM,
    ADR_STATUS,
    ITEM_TYPE,
    STAGE,
    Action,
    Client,
    Item,
    build_plan,
    desired_adr_status,
    draft_title,
    file_of,
    plan_adrs,
    plan_issues,
    seed_stage_for_adr,
)


def _adr(n, title, status="Accepted", date="2026-06-10"):
    return {"id": f"ADR-{n:03d}", "number": n, "title": title,
            "status": status, "date": date, "file": f"ADR-{n:03d}-{title}.md"}


# ── pure mapping ──────────────────────────────────────────────────────────────────


def test_file_of():
    body = sync.draft_body(_adr(41, "OpenAI Prove Fallback"))
    assert file_of(body) == "ADR-041-OpenAI Prove Fallback.md"
    # The two ADR-041 files yield distinct keys, so they never collide.
    other = sync.draft_body(_adr(41, "Proof Archive Blocks"))
    assert file_of(other) == "ADR-041-Proof Archive Blocks.md"
    assert file_of("a linked issue body with no ADR link") is None


def test_desired_adr_status():
    assert desired_adr_status("Proposed") == "Pending"
    assert desired_adr_status("Accepted") == "Accepted"
    assert desired_adr_status("Accepted (sponsor signed up: X, 2026-06-12)") == "Sponsored"
    assert desired_adr_status("Unknown") == "Accepted"  # default bucket


def test_seed_stage_for_adr():
    assert seed_stage_for_adr("Proposed") == "Backlog"
    assert seed_stage_for_adr("Accepted") == "Done"
    assert seed_stage_for_adr("Accepted (sponsor ...)") == "Done"


def test_draft_title_and_body():
    a = _adr(1, "Adopt Development Protocols")
    assert draft_title(a) == "ADR-001 — Adopt Development Protocols"
    body = sync.draft_body(a)
    assert "**Status:** Accepted" in body
    assert "ADR-001-Adopt Development Protocols.md" in body  # links the file


# ── plan_adrs ─────────────────────────────────────────────────────────────────────


def test_plan_adrs_creates_missing():
    [act] = plan_adrs([_adr(77, "Board Sync", status="Proposed")], {})
    assert act.kind == "create_adr" and act.label == "ADR-077"
    assert act.sets[ADR_STATUS] == ("select", "Pending")
    assert act.sets[STAGE] == ("select", "Backlog")  # seeded on create
    assert act.sets[ITEM_TYPE] == ("select", "ADR")
    assert act.sets[ADR_NUM] == ("number", 77)


def test_plan_adrs_enforces_status_flip_but_not_stage():
    # An existing item whose ADR flipped Proposed→Accepted, with a *curated* stage.
    a = _adr(30, "Engine", status="Accepted")
    item = Item(item_id="I1", kind="DraftIssue", title="ADR-030 — Engine",
                fields={ADR_STATUS: "Pending", ITEM_TYPE: "ADR", ADR_NUM: 30,
                        STAGE: "In Progress"})
    [act] = plan_adrs([a], {a["file"]: item})
    assert act.kind == "set_fields"
    assert act.sets[ADR_STATUS] == ("select", "Accepted")
    assert STAGE not in act.sets  # curated lane is never clobbered


def test_plan_adrs_noop_when_in_sync():
    a = _adr(1, "Adopt Development Protocols")
    item = Item(item_id="I1", kind="DraftIssue", title=draft_title(a),
                fields={ADR_STATUS: "Accepted", ITEM_TYPE: "ADR", ADR_NUM: 1,
                        STAGE: "Done"})
    assert plan_adrs([a], {a["file"]: item}) == []


def test_plan_adrs_retitles_renamed_adr():
    # Same file (stable identity), but the H1 title changed → retitle, not duplicate.
    a = _adr(1, "New Name")
    item = Item(item_id="I1", kind="DraftIssue", title="ADR-001 — Old Name",
                fields={ADR_STATUS: "Accepted", ITEM_TYPE: "ADR", ADR_NUM: 1, STAGE: "Done"})
    acts = plan_adrs([a], {a["file"]: item})
    assert [act.kind for act in acts] == ["set_title"]
    assert acts[0].title == "ADR-001 — New Name"


def test_plan_adrs_backfills_missing_type_and_number():
    a = _adr(9, "Decomp")
    item = Item(item_id="I1", kind="DraftIssue", title=draft_title(a),
                fields={ADR_STATUS: "Accepted", STAGE: "Done"})  # type/# missing
    [act] = plan_adrs([a], {a["file"]: item})
    assert act.sets[ITEM_TYPE] == ("select", "ADR")
    assert act.sets[ADR_NUM] == ("number", 9)
    assert ADR_STATUS not in act.sets  # already correct


def test_plan_adrs_keeps_duplicate_number_files_distinct():
    # Two ADR-041 files must map to two separate items, never collide on the number.
    a1 = _adr(41, "OpenAI Prove Fallback")
    a2 = _adr(41, "Proof Archive Blocks")
    i1 = Item("I1", "DraftIssue", title=draft_title(a1),
              fields={ADR_STATUS: "Accepted", ITEM_TYPE: "ADR", ADR_NUM: 41, STAGE: "Done"})
    i2 = Item("I2", "DraftIssue", title=draft_title(a2),
              fields={ADR_STATUS: "Accepted", ITEM_TYPE: "ADR", ADR_NUM: 41, STAGE: "Done"})
    assert plan_adrs([a1, a2], {a1["file"]: i1, a2["file"]: i2}) == []


# ── plan_issues ───────────────────────────────────────────────────────────────────


def test_plan_issues_backfills_type_and_closes_to_done():
    it = Item(item_id="X1", kind="Issue", number=81, state="CLOSED", fields={})
    [act] = plan_issues([it])
    assert act.sets[ITEM_TYPE] == ("select", "Issue")
    assert act.sets[STAGE] == ("select", "Done")


def test_plan_issues_seeds_open_without_stage_but_respects_triage():
    fresh = Item(item_id="X1", kind="Issue", number=1, state="OPEN",
                 fields={ITEM_TYPE: "Issue"})
    [act] = plan_issues([fresh])
    assert act.sets[STAGE] == ("select", "Backlog")

    triaged = Item(item_id="X2", kind="Issue", number=2, state="OPEN",
                   fields={ITEM_TYPE: "Issue", STAGE: "In Progress"})
    assert plan_issues([triaged]) == []  # do not clobber a curated open-issue lane


# ── end-to-end reconcile against a fake board (idempotency) ───────────────────────


class FakeClient(Client):
    """In-memory board; mutations mutate it so a re-read reflects applied state."""

    def __init__(self, items=None):
        super().__init__(runner=lambda *a, **k: {})
        self._board = list(items or [])
        self._n = 0
        self.calls = 0

    def load_schema(self):
        self.project_id = "P"
        opts = lambda *names: {n: f"opt-{n}" for n in names}
        self.fields = {
            ADR_STATUS: {"id": "f1", "options": opts("Pending", "Accepted", "Sponsored")},
            STAGE: {"id": "f2", "options": opts("Backlog", "Planned", "In Progress", "Done")},
            ITEM_TYPE: {"id": "f3", "options": opts("ADR", "Issue")},
            ADR_NUM: {"id": "f4", "options": {}},
        }

    def load_items(self):
        return [Item(i.item_id, i.kind, i.title, i.number, i.state, i.body,
                     dict(i.fields)) for i in self._board]

    def create_draft(self, title, body):
        self._n += 1
        self.calls += 1
        self._board.append(Item(f"I{self._n}", "DraftIssue", title=title, body=body,
                                fields={}))
        return f"I{self._n}"

    def set_title(self, item_id, title):
        self.calls += 1
        next(i for i in self._board if i.item_id == item_id).title = title

    def apply_sets(self, item_id, sets):
        self.calls += 1
        it = next(i for i in self._board if i.item_id == item_id)
        for fname, (kind, val) in sets.items():
            it.fields[fname] = val


def test_reconcile_is_idempotent(tmp_path):
    adrs = [_adr(1, "Adopt Protocols"), _adr(30, "Engine", status="Proposed")]
    (tmp_path / "docs" / "adrs").mkdir(parents=True)
    (tmp_path / "docs" / "adrs" / "adrs.json").write_text(
        json.dumps({"count": len(adrs), "adrs": adrs}), encoding="utf-8")

    client = FakeClient(items=[
        Item("X1", "Issue", number=81, state="CLOSED", fields={}),  # needs tidy-up
    ])

    plan1 = sync.reconcile(tmp_path, apply=True, client=client)
    assert plan1, "first run should have work (2 ADRs to create + 1 issue to tidy)"

    # Second run over the now-populated board: nothing left to do.
    client.calls = 0
    plan2 = sync.reconcile(tmp_path, apply=True, client=client)
    assert plan2 == []
    assert client.calls == 0

    # And the board ended up correct.
    board = {i.title or f"#{i.number}": i for i in client.load_items()}
    assert board["ADR-030 — Engine"].fields[ADR_STATUS] == "Pending"
    assert board["ADR-030 — Engine"].fields[STAGE] == "Backlog"
    assert board["#81"].fields[STAGE] == "Done"


# ── CLI ───────────────────────────────────────────────────────────────────────────


def test_cli_requires_exactly_one_mode():
    assert sync.main([]) == 2
    assert sync.main(["--check", "--sync"]) == 2


def test_cli_check_reports_drift(monkeypatch):
    monkeypatch.setattr(sync, "reconcile",
                        lambda root, apply: [Action("set_fields", "ADR-1")])
    assert sync.main(["--check", "."]) == 1


def test_cli_check_clean(monkeypatch):
    monkeypatch.setattr(sync, "reconcile", lambda root, apply: [])
    assert sync.main(["--check", "."]) == 0


def test_cli_sync_applies(monkeypatch):
    seen = {}

    def fake(root, apply):
        seen["apply"] = apply
        return []

    monkeypatch.setattr(sync, "reconcile", fake)
    assert sync.main(["--sync", "."]) == 0
    assert seen["apply"] is True


def test_cli_degrades_when_board_unreachable(monkeypatch):
    def boom(root, apply):
        raise sync.GraphQLError("PROJECTS_TOKEN unset")
    monkeypatch.setattr(sync, "reconcile", boom)
    assert sync.main(["--sync", "."]) == 0  # warns, does not fail the build
