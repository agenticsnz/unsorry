"""Close coordination/prove PRs whose action `main` has already satisfied.

Duplicates pile up and cost real resources: several agents decompose the same
goal (first-merge-wins, the rest conflict), identical `unblock(G)` PRs stack up,
or a `prove(G)` PR lingers after G is proved. The losers can never merge or are
no-ops, yet they consume Gate A runs, the submission-governor in-flight budget,
reviewer attention, and queue space. This closes any open PR whose action `main`
already shows done:

  prove(G)      → G is proved/archived on main
  decompose(G)  → G already has a decomposition record on main
  unblock(G)    → G is no longer `status≜blocked` on main

Conservative: a PR is closed only on a POSITIVE already-satisfied signal; an
unknown goal, an unrecognised title, or a still-pending action is left untouched.
Uses the default GITHUB_TOKEN (`pull-requests: write` to close; it opens nothing,
so no REFRESH_TOKEN is needed).

Usage:
  python3 -m tools.repo.superseded_prs            # dry-run: list what would close
  python3 -m tools.repo.superseded_prs --apply    # actually close (bounded)
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from tools.gate_b.records import parse_record

# A coordination/prove PR title is `<action>(<goal>): …`.
_TITLE_RE = re.compile(r"^\s*(?P<action>prove|decompose|unblock)\((?P<goal>[^)]+)\)\s*:")
DONE_STATUSES = frozenset({"proved", "archived"})


def parse_pr_action(title: str) -> tuple[str, str] | None:
    """(action, goal) from a PR title `<action>(<goal>): …`, or None."""
    m = _TITLE_RE.match(title or "")
    return (m.group("action"), m.group("goal")) if m else None


def decomposed_goals(root: Path) -> set[str]:
    """Goal ids that already have a decomposition record on main."""
    out: set[str] = set()
    d = root / "decompositions"
    if d.is_dir():
        for path in d.glob("*.aisp"):
            parent = parse_record(path.read_text(encoding="utf-8")).fields.get("parent")
            if parent:
                out.add(parent)
    return out


def goal_statuses(root: Path) -> dict[str, str]:
    """goal id → status, from active goals/*.aisp."""
    out: dict[str, str] = {}
    g = root / "goals"
    if g.is_dir():
        for path in g.glob("*.aisp"):
            st = parse_record(path.read_text(encoding="utf-8")).fields.get("status")
            if st:
                out[path.stem] = st
    return out


def is_superseded(action: str, goal: str,
                  decomposed: set[str], statuses: dict[str, str]) -> bool:
    """Pure: has `main` already satisfied this PR's action? Conservative — an
    unknown goal or unrecognised action returns False (leave the PR alone)."""
    if action == "prove":
        return statuses.get(goal) in DONE_STATUSES
    if action == "decompose":
        return goal in decomposed
    if action == "unblock":
        st = statuses.get(goal)
        return st is not None and st != "blocked"   # no longer blocked → moot
    return False


def _open_prs(repo: str | None) -> list[dict]:
    cmd = ["gh", "pr", "list", "--state", "open", "--limit", "400",
           "--json", "number,title"]
    if repo:
        cmd += ["--repo", repo]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True, check=False)
    if proc.returncode != 0:
        print(f"warning: gh pr list failed: {proc.stderr.strip()}", file=sys.stderr)
        return []
    return json.loads(proc.stdout or "[]")


def _close(number: int, repo: str | None, reason: str) -> bool:
    cmd = ["gh", "pr", "close", str(number), "--comment", reason]
    if repo:
        cmd += ["--repo", repo]
    return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                          text=True, check=False).returncode == 0


_REASON = {
    "prove": "goal already proved/archived on main",
    "decompose": "goal already decomposed on main (first-merge-wins; this is a "
                 "competing duplicate decomposition)",
    "unblock": "goal is no longer blocked on main (unblock already satisfied)",
}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.superseded_prs",
        description="Close coordination/prove PRs whose action main already satisfied.")
    ap.add_argument("--root", default=".", help="repo root with goals/ + decompositions/")
    ap.add_argument("--repo", default=None, help="owner/name (default: gh's repo)")
    ap.add_argument("--apply", action="store_true", help="close (default: dry-run)")
    ap.add_argument("--limit", type=int, default=200, help="max PRs to close per run")
    args = ap.parse_args(argv)

    root = Path(args.root)
    decomposed = decomposed_goals(root)
    statuses = goal_statuses(root)

    superseded: list[tuple[int, str, str, str]] = []  # (number, action, goal, reason)
    for pr in _open_prs(args.repo):
        parsed = parse_pr_action(pr.get("title", ""))
        if parsed is None:
            continue
        action, goal = parsed
        if is_superseded(action, goal, decomposed, statuses):
            superseded.append((int(pr["number"]), action, goal, _REASON[action]))

    capped = superseded[: args.limit]
    print(f"superseded-PR janitor: {len(superseded)} superseded, acting on "
          f"{len(capped)} ({'APPLY' if args.apply else 'DRY-RUN'})")
    closed = 0
    for number, action, goal, reason in capped:
        line = f"#{number} {action}({goal}) — {reason}"
        if not args.apply:
            print(f"  would close {line}")
            continue
        msg = (f"Closing as superseded: {reason}. This duplicate cannot merge "
               f"and would only consume Gate A / queue budget. No work lost.")
        if _close(number, args.repo, msg):
            closed += 1
            print(f"  closed {line}")
        else:
            print(f"  failed to close #{number}", file=sys.stderr)
    if args.apply:
        print(f"superseded-PR janitor: closed {closed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
