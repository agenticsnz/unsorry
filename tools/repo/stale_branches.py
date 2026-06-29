"""Delete stale `queued/prove/*` branches whose goal is already proved.

A queued proof branch is produced by a prover and waits for the dispatcher to open
it as a PR. But once its goal is proved+merged (and usually archived), the branch
is dead weight: the dispatcher correctly skips it (opening it would be a duplicate
PR, the #3077 conflict), yet it lingers forever. Thousands accumulate — observed
~2.7k stale of ~2.9k total — and every dispatcher pass lists and re-checks them all.

This removes branches whose goal is **provably done** (its active `goals/<id>.aisp`
carries `status≜proved` or `status≜archived`). Conservative by design: a goal that
is still open, or whose record is missing/ambiguous, is left untouched — only a
positive proved/archived signal deletes a branch. Deletions are batched (many refs
per push) and bounded per run.

Usage:
  python3 -m tools.repo.stale_branches            # dry-run: list what would go
  python3 -m tools.repo.stale_branches --apply    # actually delete (bounded)
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

from tools.gate_b.records import parse_record

QUEUED_PREFIX = "queued/prove/"
DONE_STATUSES = frozenset({"proved", "archived"})
_BRANCH_RE = re.compile(r"^queued/prove/(?P<goal>[^/]+)/[^/]+$")


def goal_of_branch(ref: str) -> str | None:
    """The goal id embedded in a `queued/prove/<goal>/<agent>-<hex>` ref, or None."""
    m = _BRANCH_RE.match(ref.strip())
    return m.group("goal") if m else None


def done_goals(root: Path) -> set[str]:
    """Goal ids whose active record marks them proved or archived (i.e. done)."""
    done: set[str] = set()
    goals_dir = root / "goals"
    if not goals_dir.is_dir():
        return done
    for path in sorted(goals_dir.glob("*.aisp")):
        rec = parse_record(path.read_text(encoding="utf-8"))
        if rec.fields.get("status") in DONE_STATUSES:
            done.add(path.stem)
    return done


def is_stale(ref: str, done: set[str]) -> bool:
    """Pure predicate: a queued branch is stale iff its goal is provably done."""
    goal = goal_of_branch(ref)
    return goal is not None and goal in done


def _remote_queued_branches(repo: str | None) -> list[str]:
    cmd = ["git", "ls-remote", "--heads", repo or "origin", f"refs/heads/{QUEUED_PREFIX}*"]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True, check=False)
    if proc.returncode != 0:
        print(f"warning: git ls-remote failed: {proc.stderr.strip()}", file=sys.stderr)
        return []
    refs = []
    for line in proc.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) == 2 and parts[1].startswith("refs/heads/"):
            refs.append(parts[1][len("refs/heads/"):])
    return refs


def _delete_batch(remote: str, branches: list[str]) -> bool:
    cmd = ["git", "push", remote, *[f":refs/heads/{b}" for b in branches]]
    return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                          text=True, check=False).returncode == 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.stale_branches",
        description="Delete queued/prove/* branches whose goal is already proved.")
    ap.add_argument("--root", default=".", help="repo root with goals/ (default: .)")
    ap.add_argument("--remote", default="origin")
    ap.add_argument("--apply", action="store_true", help="actually delete (default: dry-run)")
    ap.add_argument("--limit", type=int, default=500, help="max branches per run")
    ap.add_argument("--batch", type=int, default=100, help="refs per git push")
    args = ap.parse_args(argv)

    done = done_goals(Path(args.root))
    branches = _remote_queued_branches(args.remote)
    stale = [b for b in branches if is_stale(b, done)]
    capped = stale[: args.limit]

    print(f"stale-branch janitor: {len(branches)} queued branches, {len(stale)} stale "
          f"(goal proved/archived), acting on {len(capped)} this run "
          f"(limit {args.limit}; {'APPLY' if args.apply else 'DRY-RUN'})")
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
    print(f"stale-branch janitor: deleted {deleted} branch(es)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
