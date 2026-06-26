"""Recover stranded *mergeable* prove PRs the swarm's finalization step missed.

The Gate A/B *compute* keeps up with load, but completed work strands in the
finalization layer. Two gaps the existing janitors do NOT cover (ADR-105):

  1. ARM — a SAME-repo prove PR whose auto-merge was never armed at creation
     (e.g. the enrol step hit a token error) sits green-but-unmerged forever.
     ``fork_automerge.py`` only arms CROSS-repo PRs (ADR-068); this arms the
     same-repo swarm PRs it leaves behind. GitHub still blocks the merge until
     Gate A/B are green — this only *arms* it (ADR-005); soundness is untouched.

  2. RERUN — a ``gate-a`` that FAILED *only because a sub-job was CANCELLED*
     (the concurrency ``cancel-in-progress`` killed an audit/replay leg, so the
     cover job cascaded to failure) is recoverable: the proof is fine, nothing
     is wrong with it. ``dropped_gate_prs.py`` treats any cancelled/failed gate
     as a real block and leaves it (correctly, for its purpose). This re-runs
     EXACTLY the cancellation-induced failures and nothing else — a genuine
     check failure (a bad proof, a failed admission policy) is left alone.

Both halves are conservative, bounded, and dry-run by default. The selection
logic is pure and stdin-driven (mirrors ``fork_automerge`` / ``pr_protocol``) so
it is unit-tested without ``gh``.
"""
from __future__ import annotations

import json
import re
import sys

#: ADR-026 prove title — the type+scope must be the first token.
PROVE_TITLE_RE = re.compile(r"^prove\([^)]+\):")

#: The only paths a verified prove PR ever touches (submit_pr_tree adds exactly
#: ``library goals proof-runs``). Anything outside — a gate, harness, workflow,
#: lakefile — means it is NOT a plain proof and must not be armed by automation
#: (CODEOWNERS also guards those; this is defence in depth). Mirrors
#: ``fork_automerge.ALLOW_PREFIXES`` deliberately (same trust boundary).
ALLOW_PREFIXES = ("library/", "goals/", "proof-runs/")

#: A gate-a job whose FAILURE is a downstream cascade of a cancelled leg, not a
#: genuine check result. A failure in any OTHER job (a leaf check, the library
#: build, or ``admission``) is genuine and must NOT be treated as recoverable.
_CASCADE_JOB_RE = re.compile(r"(-cover$)|(^gate-a$)")


def _paths(pr: dict) -> list[str]:
    out: list[str] = []
    for entry in pr.get("files") or []:
        if isinstance(entry, dict) and entry.get("path"):
            out.append(entry["path"])
        elif isinstance(entry, str):
            out.append(entry)
    return out


def within_allow(paths: list[str], allow_prefixes=ALLOW_PREFIXES) -> bool:
    """True iff there is ≥1 path and every path starts with an allowed prefix."""
    return bool(paths) and all(
        any(p.startswith(prefix) for prefix in allow_prefixes) for p in paths
    )


def should_arm(pr: dict, allow_prefixes=ALLOW_PREFIXES) -> bool:
    """Whether to arm auto-merge on this PR (the item-1 gap).

    A plain SAME-repo prove PR (ADR-026 title, proof-only diff), not a draft,
    not already armed, and not in a conflicted (DIRTY) state. Cross-repo PRs are
    owned by ``fork-automerge-enabler`` (ADR-068) — left to it to avoid a double
    arm. Arming a not-yet-green PR is fine: GitHub fires the merge only once the
    required gates pass (ADR-005)."""
    if pr.get("isCrossRepository"):
        return False                                  # owned by fork-automerge-enabler
    if pr.get("isDraft"):
        return False
    if pr.get("autoMergeRequest"):
        return False                                  # already armed
    if not PROVE_TITLE_RE.match(pr.get("title", "")):
        return False                                  # only prove PRs
    if pr.get("mergeStateStatus") == "DIRTY":
        return False                                  # conflict — arming is futile
    return within_allow(_paths(pr), allow_prefixes)


def gate_failure_is_cancellation(jobs) -> bool:
    """Pure: did this ``gate-a`` run fail ONLY because a sub-job was cancelled?

    ``jobs`` is an iterable of dicts with ``name`` + ``conclusion``. Returns True
    iff at least one job was ``cancelled`` AND no NON-cascade job genuinely
    ``failure``-d. A leaf-check / build / ``admission`` failure (a real block) →
    False (leave it). A cover/aggregate failure that merely reflects a cancelled
    leg → not counted as genuine, so the run is recoverable by a re-run."""
    cancelled = False
    genuine_failure = False
    for j in jobs:
        concl = (j.get("conclusion") or "").lower()
        name = j.get("name") or ""
        if concl == "cancelled":
            cancelled = True
        elif concl == "failure" and not _CASCADE_JOB_RE.search(name):
            genuine_failure = True
    return cancelled and not genuine_failure


def select_arm(prs, allow_prefixes=ALLOW_PREFIXES, limit=None) -> list[int]:
    """PR numbers to arm, oldest-number first, capped at ``limit`` if given."""
    nums = sorted(
        pr["number"] for pr in prs if "number" in pr and should_arm(pr, allow_prefixes)
    )
    return nums[:limit] if limit is not None else nums


# ---------------------------------------------------------------------------
# CLI: two pure selectors over stdin JSON. The I/O shell (gh calls, rerun,
# arm) lives in the workflow so the decision logic stays unit-tested.
# ---------------------------------------------------------------------------

def _usage() -> int:
    print(
        "usage:\n"
        "  ... | python3 -m tools.repo.finalization_recovery arm [--limit N]\n"
        "        # PR JSON array on stdin -> prints PR numbers to arm\n"
        "  ... | python3 -m tools.repo.finalization_recovery is-cancellation\n"
        "        # gate-a jobs JSON array on stdin -> prints 'true'/'false'",
        file=sys.stderr,
    )
    return 2


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if not argv:
        return _usage()
    cmd, rest = argv[0], argv[1:]
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        data = []
    if cmd == "arm":
        limit = None
        if "--limit" in rest:
            try:
                limit = max(0, int(rest[rest.index("--limit") + 1]))
            except (IndexError, ValueError):
                print("--limit needs an integer", file=sys.stderr)
                return 2
        prs = data if isinstance(data, list) else []
        for number in select_arm(prs, limit=limit):
            print(number)
        return 0
    if cmd == "is-cancellation":
        jobs = data if isinstance(data, list) else []
        print("true" if gate_failure_is_cancellation(jobs) else "false")
        return 0
    return _usage()


if __name__ == "__main__":
    raise SystemExit(main())
