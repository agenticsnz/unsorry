"""Arm auto-merge on admissible fork prove PRs (ADR-068 / SPEC-068-A §6).

A fork contributor cannot arm auto-merge on their cross-repo PR — they have no
write access to the upstream. This selector, run by the `fork-automerge-enabler`
workflow with the admin `REFRESH_TOKEN`, picks the open PRs the upstream may
safely arm: a **cross-repository** PR whose title is a `prove(<goal>):` title
(ADR-026), whose diff touches **only** the proof allow-paths (`library/`,
`goals/`, `proof-runs/` — never the gates, harness, or workflows), and that does
not already have auto-merge armed. GitHub still blocks the merge until Gate A and
Gate B are green; this only *arms* it (ADR-005). Soundness is never trusted from
the fork — Gate A re-verifies every PR on the kernel.

Selection is pure and stdin-driven (mirrors `tools.repo.pr_protocol`) so it is
unit-tested without `gh`:

  gh pr list --state open --limit 200 \\
    --json number,title,isCrossRepository,files,autoMergeRequest \\
    | python3 -m tools.repo.fork_automerge select [--limit N]

It prints the PR numbers to arm, one per line. A PR whose `files` are absent or
empty is treated as NOT admissible (fail-closed: never arm a diff we cannot see).
"""
from __future__ import annotations

import json
import re
import sys

#: ADR-026 prove title: the type+scope must be the first token.
PROVE_TITLE_RE = re.compile(r"^prove\([^)]+\):")

#: The only paths a verified prove PR ever touches (submit_pr_tree adds exactly
#: `library goals proof-runs`). Anything outside these — a gate, the harness, a
#: workflow, a lakefile — means the PR is NOT a plain proof and must not be armed
#: by this automation (CODEOWNERS also guards them; this is defence in depth).
ALLOW_PREFIXES = ("library/", "goals/", "proof-runs/")


def _paths(pr: dict) -> list[str]:
    """The changed file paths of a PR (gh returns files as {path, additions, …})."""
    out: list[str] = []
    for entry in pr.get("files") or []:
        if isinstance(entry, dict) and entry.get("path"):
            out.append(entry["path"])
        elif isinstance(entry, str):
            out.append(entry)
    return out


def within_allow(paths: list[str], allow_prefixes=ALLOW_PREFIXES) -> bool:
    """True iff every path starts with an allowed prefix (and there is ≥1 path)."""
    return bool(paths) and all(
        any(p.startswith(prefix) for prefix in allow_prefixes) for p in paths
    )


def is_admissible(pr: dict, allow_prefixes=ALLOW_PREFIXES) -> bool:
    """Whether the upstream may arm auto-merge on this fork PR (SPEC-068-A §6)."""
    if not pr.get("isCrossRepository"):
        return False  # only fork PRs need the upstream to arm them
    if not PROVE_TITLE_RE.match(pr.get("title", "")):
        return False  # only prove PRs (ADR-026); never docs/chore/sourcing
    if pr.get("autoMergeRequest"):
        return False  # already armed
    return within_allow(_paths(pr), allow_prefixes)


def select(prs: list[dict], allow_prefixes=ALLOW_PREFIXES, limit: int | None = None) -> list[int]:
    """The PR numbers to arm, oldest-number first, capped at `limit` if given."""
    nums = sorted(
        pr["number"] for pr in prs if "number" in pr and is_admissible(pr, allow_prefixes)
    )
    return nums[:limit] if limit is not None else nums


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if not argv or argv[0] != "select":
        print("usage: fork_automerge.py select [--limit N]   # PR JSON array on stdin", file=sys.stderr)
        return 2
    limit: int | None = None
    rest = argv[1:]
    if "--limit" in rest:
        i = rest.index("--limit")
        try:
            limit = int(rest[i + 1])
        except (IndexError, ValueError):
            print("--limit needs an integer", file=sys.stderr)
            return 2
        if limit < 0:
            limit = 0
    try:
        prs = json.load(sys.stdin)
    except json.JSONDecodeError:
        prs = []
    if not isinstance(prs, list):
        prs = []
    for number in select(prs, limit=limit):
        print(number)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
