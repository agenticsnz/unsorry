"""Duplicate-verifier-waste metric (ADR-070 / SPEC-070-A), Phase-2 step 2a.

Claimless fork proving (ADR-068) lets two forks prove the same goal; each runs a
Gate A verification and first-merge-wins closes the loser. This read-only metric
quantifies that waste from the prove-PR history, so the build/no-build decision
for the Phase-2 sharded selection (SPEC-053-A §8.3) and fork-writable lease (§8.4)
is evidence-gated, not a guess.

Pure and stdin-driven (mirrors `tools.repo.pr_protocol` / `tools.repo.fork_automerge`)
so `summarize()` is unit-tested without `gh`:

  gh pr list --state all --limit 1000 \\
    --json number,title,state,isCrossRepository,mergedAt \\
    | python3 -m tools.repo.fork_waste summarize [--write docs/metrics/fork-waste.json]

It is advisory analytics — nothing in the harness consumes it, and it never gates
selection, admission, or merge.
"""
from __future__ import annotations

import json
import re
import sys

#: ADR-026 prove title; the goal id is the parenthesised scope.
PROVE_TITLE_RE = re.compile(r"^prove\(([^)]+)\):")

#: How many colliding goals to list in `top_collisions`.
TOP_COLLISIONS = 10


def prove_goal(title: str) -> str | None:
    """The goal id of a `prove(<goal>):` title, or None for a non-prove title."""
    m = PROVE_TITLE_RE.match(title or "")
    return m.group(1) if m else None


def _is_merged(pr: dict) -> bool:
    return pr.get("state") == "MERGED" or bool(pr.get("mergedAt"))


def _is_closed_unmerged(pr: dict) -> bool:
    return pr.get("state") == "CLOSED" and not pr.get("mergedAt")


def summarize(prs: list[dict]) -> dict:
    """The SPEC-070-A §3 summary. Pure: a function of `prs` only."""
    # Group prove PRs by goal, recording per-PR fork/merge/closed state.
    by_goal: dict[str, list[dict]] = {}
    for pr in prs:
        goal = prove_goal(pr.get("title", ""))
        if goal is None:
            continue
        by_goal.setdefault(goal, []).append(pr)

    prove_prs = fork_prove_prs = fork_merged = fork_open = fork_closed_unmerged = 0
    goals_with_multiple = goals_with_fork_collision = 0
    collisions: list[dict] = []

    for goal, goal_prs in by_goal.items():
        prove_prs += len(goal_prs)
        fork_prs = [p for p in goal_prs if p.get("isCrossRepository")]
        fork_prove_prs += len(fork_prs)
        merged_here = sum(1 for p in goal_prs if _is_merged(p))
        for p in fork_prs:
            if _is_merged(p):
                fork_merged += 1
            elif _is_closed_unmerged(p):
                fork_closed_unmerged += 1
            else:
                fork_open += 1
        if len(goal_prs) > 1:
            goals_with_multiple += 1
            if fork_prs:
                goals_with_fork_collision += 1
                collisions.append(
                    {
                        "goal": goal,
                        "prove_prs": len(goal_prs),
                        "fork_prove_prs": len(fork_prs),
                        "merged": merged_here,
                    }
                )

    collisions.sort(key=lambda c: (-c["prove_prs"], -c["fork_prove_prs"], c["goal"]))
    ratio = round(fork_closed_unmerged / fork_prove_prs, 4) if fork_prove_prs else 0.0

    return {
        "prove_prs": prove_prs,
        "fork_prove_prs": fork_prove_prs,
        "fork_merged": fork_merged,
        "fork_open": fork_open,
        "fork_closed_unmerged": fork_closed_unmerged,
        "fork_waste_ratio": ratio,
        "goals_with_multiple_prove_prs": goals_with_multiple,
        "goals_with_fork_collision": goals_with_fork_collision,
        "estimated_wasted_gate_a_runs": fork_closed_unmerged,
        "top_collisions": collisions[:TOP_COLLISIONS],
    }


def _human(summary: dict) -> str:
    return (
        f"fork prove PRs: {summary['fork_prove_prs']} "
        f"(merged {summary['fork_merged']}, open {summary['fork_open']}, "
        f"wasted {summary['fork_closed_unmerged']}); "
        f"waste ratio {summary['fork_waste_ratio']}; "
        f"fork collisions on {summary['goals_with_fork_collision']} goal(s); "
        f"~{summary['estimated_wasted_gate_a_runs']} Gate A run(s) wasted"
    )


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if not argv or argv[0] != "summarize":
        print("usage: fork_waste.py summarize [--write PATH]   # PR JSON array on stdin", file=sys.stderr)
        return 2
    write_path = None
    rest = argv[1:]
    if "--write" in rest:
        i = rest.index("--write")
        if i + 1 >= len(rest):
            print("--write needs a path", file=sys.stderr)
            return 2
        write_path = rest[i + 1]
    try:
        prs = json.load(sys.stdin)
    except json.JSONDecodeError:
        prs = []
    if not isinstance(prs, list):
        prs = []
    summary = summarize(prs)
    text = json.dumps(summary, indent=2, ensure_ascii=False)
    if write_path:
        with open(write_path, "w", encoding="utf-8") as fh:
            fh.write(text + "\n")
        print(_human(summary), file=sys.stderr)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
