"""Expired-claim reaper (SPEC-004-A, ADR-004).

Removes claims whose TTL has elapsed from a checkout of the ``claims``
branch. Expiry verdicts come from :mod:`tools.gate_b.claims` — the same
implementation Gate B's validator uses, so the two can never disagree.

CLI: ``python3 -m tools.gate_b.reaper <root> [--at ISO8601Z] [--dry-run] [--json]``

Exit codes: 0 clean (including "reaped some"), 1 unparsable claims seen
(never deleted), 2 internal error (e.g. no ``claims/`` directory).
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from .claims import expires_at, is_expired, parse_claim
from .records import parse_utc_z


def reap(root: Path, now: datetime, dry_run: bool) -> dict:
    claims_dir = root / "claims"
    if not claims_dir.is_dir():
        raise FileNotFoundError(f"no claims/ directory under {root}")

    reaped: list[dict] = []
    unparsable: list[str] = []
    kept = 0
    for path in sorted(claims_dir.glob("*.aisp")):
        claim = parse_claim(path)
        expiry = expires_at(claim)
        if expiry is None:
            unparsable.append(f"claims/{path.name}")
            continue
        if is_expired(claim, now):
            reaped.append(
                {
                    "path": f"claims/{path.name}",
                    "goal": claim.goal,
                    "agent": claim.agent,
                    "expired_for_seconds": int((now - expiry).total_seconds()),
                }
            )
            if not dry_run:
                path.unlink()
        else:
            kept += 1

    return {
        "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "dry_run": dry_run,
        "reaped": reaped,
        "kept": kept,
        "unparsable": unparsable,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tools.gate_b.reaper")
    parser.add_argument("root", type=Path, help="checkout of the claims branch")
    parser.add_argument("--at", help="ISO-8601 UTC clock injection (default: now)")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args(argv)

    if args.at is not None:
        now = parse_utc_z(args.at)
        if now is None:
            print(f"unparsable --at value: {args.at}", file=sys.stderr)
            return 2
    else:
        now = datetime.now(timezone.utc)

    try:
        report = reap(args.root, now, args.dry_run)
    except FileNotFoundError as exc:
        if args.as_json:
            print(json.dumps({"error": str(exc)}, sort_keys=True))
        else:
            print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.as_json:
        print(json.dumps(report, sort_keys=True))
    else:
        for entry in report["reaped"]:
            verb = "would reap" if args.dry_run else "reaped"
            print(f"{verb} {entry['path']} (expired {entry['expired_for_seconds']}s ago)")
        for path in report["unparsable"]:
            print(f"unparsable (left in place): {path}")
        print(f"kept {report['kept']} live claim(s)")

    return 1 if report["unparsable"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
