"""Delete remote branches whose pull request is already merged or closed.

`delete_branch_on_merge` is off on this repo, so every squash-merged PR leaves its
head branch behind (squash makes the branch tip a non-ancestor of `main`, so a
``git branch --merged`` prune can't see it). Thousands accumulate — ~1.1k
`feature/*` alone — cluttering the ref space and slowing every full ref listing.
``stale_branches.py`` only handles `queued/prove/*` (by goal status); this is its
complement for the PR-bearing branches (`feature/`, `fix/`, `docs/`, …).

A branch is prunable iff it has ≥1 PR and **all** of its PRs are terminal
(MERGED/CLOSED) with **none OPEN**, and it is not a protected/owned ref. A branch
with no PR at all is left alone (it is not ours to judge — e.g. `claims`, an
in-flight queued branch). Conservative, bounded, dry-run by default.

Usage:
  python3 -m tools.repo.merged_pr_branches            # dry-run: list what would go
  python3 -m tools.repo.merged_pr_branches --apply    # delete (bounded, batched)
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys

#: Never delete these exact refs or anything under these prefixes. `queued/` is
#: owned by stale_branches.py (goal-status driven); `main`/`claims`/`gh-pages` are
#: load-bearing (ADR-004 claims branch, the default branch, the legacy pages src).
PROTECTED_EXACT = frozenset({"main", "claims", "gh-pages", "HEAD"})
PROTECTED_PREFIXES = ("queued/",)

TERMINAL_STATES = frozenset({"MERGED", "CLOSED"})


def is_protected(branch: str) -> bool:
    return branch in PROTECTED_EXACT or branch.startswith(PROTECTED_PREFIXES)


def is_prunable(branch: str, states) -> bool:
    """Pure: delete iff the branch has only terminal PRs (≥1, none OPEN) and is not
    protected. ``states`` is the set of PR states for this branch (empty if it never
    had a PR — then NOT prunable, we only remove branches whose PR work is done)."""
    if is_protected(branch):
        return False
    s = set(states)
    if not s or "OPEN" in s:
        return False
    return s <= TERMINAL_STATES


def branch_states(prs) -> dict:
    """branch -> set of PR states, from a list of {headRefName, state} dicts."""
    out: dict = {}
    for pr in prs:
        ref = pr.get("headRefName")
        st = pr.get("state")
        if ref and st:
            out.setdefault(ref, set()).add(st)
    return out


def select(remote_branches, states_by_branch, limit=None) -> list:
    """Prunable branch names (sorted), capped at ``limit``. A remote branch with no
    PR record is skipped (only branches whose PR is terminal are removed)."""
    out = sorted(
        b for b in remote_branches
        if is_prunable(b, states_by_branch.get(b, set()))
    )
    return out[:limit] if limit is not None else out


# ---------------------------------------------------------------------------
# I/O shell
# ---------------------------------------------------------------------------

def _remote_branches(remote: str) -> list:
    proc = subprocess.run(["git", "ls-remote", "--heads", remote],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
    if proc.returncode != 0:
        print(f"warning: git ls-remote failed: {proc.stderr.strip()}", file=sys.stderr)
        return []
    refs = []
    for line in proc.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) == 2 and parts[1].startswith("refs/heads/"):
            refs.append(parts[1][len("refs/heads/"):])
    return refs


def _all_pr_states(repo: str | None, window: int) -> dict:
    args = ["pr", "list", "--state", "all", "--limit", str(window),
            "--json", "headRefName,state"]
    if repo:
        args += ["--repo", repo]
    proc = subprocess.run(["gh", *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True, check=False)
    if proc.returncode != 0:
        print(f"warning: gh pr list failed: {proc.stderr.strip()}", file=sys.stderr)
        return {}
    try:
        prs = json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        prs = []
    return branch_states(prs if isinstance(prs, list) else [])


def _delete_batch(remote: str, branches: list) -> bool:
    cmd = ["git", "push", remote, *[f":refs/heads/{b}" for b in branches]]
    return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                          text=True, check=False).returncode == 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.merged_pr_branches",
        description="Delete remote branches whose PR is merged/closed.")
    ap.add_argument("--repo", default=None, help="owner/name (default: gh's repo)")
    ap.add_argument("--remote", default="origin")
    ap.add_argument("--apply", action="store_true", help="actually delete (default: dry-run)")
    ap.add_argument("--limit", type=int, default=300, help="max branches per run")
    ap.add_argument("--batch", type=int, default=50, help="refs per git push")
    ap.add_argument("--pr-window", type=int, default=5000,
                    help="how many recent PRs to read state from")
    args = ap.parse_args(argv)

    states = _all_pr_states(args.repo, args.pr_window)
    remote = _remote_branches(args.remote)
    capped = select(remote, states, limit=args.limit)
    prunable_total = len(select(remote, states))

    print(f"merged-PR-branch janitor: {len(remote)} remote branches, "
          f"{prunable_total} with a terminal (merged/closed) PR, acting on {len(capped)} "
          f"({'APPLY' if args.apply else 'DRY-RUN'}; PR window {args.pr_window})")
    if prunable_total > len(capped):
        print(f"  note: capped at --limit {args.limit}; {prunable_total - len(capped)} "
              f"left for the next run")
    if not args.apply:
        for b in capped[:20]:
            print(f"  would delete {b}")
        if len(capped) > 20:
            print(f"  … and {len(capped) - 20} more")
        return 0

    deleted = 0
    for i in range(0, len(capped), args.batch):
        chunk = capped[i:i + args.batch]
        if _delete_batch(args.remote, chunk):
            deleted += len(chunk)
            print(f"  deleted {deleted}/{len(capped)}")
        else:
            print(f"  batch delete failed at offset {i}", file=sys.stderr)
    print(f"merged-PR-branch janitor: deleted {deleted} branch(es)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
