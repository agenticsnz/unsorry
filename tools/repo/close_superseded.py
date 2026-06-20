"""Close stranded direct proof PRs whose goal is now proved (ADR-058 cleanup).

A direct ``prove(...)`` PR that was re-routed onto the queued path (see
``tools/repo/reroute_stranded``), or whose goal a peer proved, becomes
**superseded** once its goal reaches ``status≜proved`` (or ``archived``) on
``main`` — i.e. its re-route landed. This sweep closes exactly those, and
**never** a PR whose goal is still open. It is the safe, incremental
implementation of "close the originals once their re-routes land" for the
ruv-sledgehammer cleanup (#1904) and the capacity drain (#1909).

Usage:
  python3 -m tools.repo.close_superseded [--author <login>] [--repo .] [--dry-run]
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys

from tools.repo.reroute_stranded import parse_prove_title  # DRY: one prove-title parser

SUPERSEDED_STATUSES = ("proved", "archived")
_STATUS_RE = re.compile(r"status≜([A-Za-z0-9-]+)")


def is_superseded(status: str | None) -> bool:
    """A goal whose proof has landed — closing its stranded direct PR is safe."""
    return status in SUPERSEDED_STATUSES


def goal_status_from_text(text: str | None) -> str | None:
    """The ``status≜`` value from a goal record's text, or None."""
    if not text:
        return None
    m = _STATUS_RE.search(text)
    return m.group(1) if m else None


# --------------------------------------------------------------- orchestration


def _run(args: list[str], repo: str, capture: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(
        args, cwd=repo, check=False, text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def _goal_status(repo: str, goal: str, base: str) -> str | None:
    out = _run(["git", "show", f"{base}:goals/{goal}.aisp"], repo)
    return goal_status_from_text(out.stdout) if out.returncode == 0 else None


def sweep(repo: str = ".", author: str | None = None, base: str = "origin/main",
          dry_run: bool = False) -> list[tuple[int, str]]:
    """Close every open direct ``prove(...)`` PR whose goal is proved on ``base``.

    Returns the ``(pr, goal)`` pairs it closed (or would close, under dry_run).
    """
    _run(["git", "fetch", "-q", "origin"], repo)
    listing = ["gh", "pr", "list", "--state", "open", "--limit", "400",
               "--json", "number,title"]
    if author:
        listing += ["--author", author]
    out = _run(listing, repo)
    if out.returncode != 0:
        raise RuntimeError(f"gh pr list failed: {out.stderr.strip()}")
    import json
    closed: list[tuple[int, str]] = []
    for pr in json.loads(out.stdout):
        try:
            goal, _ = parse_prove_title(pr["title"])
        except ValueError:
            continue  # not a prove(...) PR — leave it alone
        if not is_superseded(_goal_status(repo, goal, base)):
            continue
        if not dry_run:
            comment = (
                f"Goal `{goal}` is now proved on `main` (its queued re-route or a "
                f"peer landed). Closing this superseded stranded direct submission "
                f"(#1904 / #1909 cleanup)."
            )
            _run(["gh", "pr", "close", str(pr["number"]), "--comment", comment], repo)
        closed.append((pr["number"], goal))
    return closed


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python3 -m tools.repo.close_superseded")
    p.add_argument("--author", help="restrict to one PR author (e.g. ruvnet)")
    p.add_argument("--repo", default=".", help="repository root (default: cwd)")
    p.add_argument("--base", default="origin/main", help="ref to read goal status from")
    p.add_argument("--dry-run", action="store_true", help="report, do not close")
    args = p.parse_args(argv)
    try:
        closed = sweep(args.repo, args.author, args.base, args.dry_run)
    except RuntimeError as exc:
        print(f"close_superseded: {exc}", file=sys.stderr)
        return 1
    verb = "would close" if args.dry_run else "closed"
    for pr, goal in closed:
        print(f"{verb} #{pr} ({goal})")
    print(f"=== {verb} {len(closed)} superseded PR(s) ===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
