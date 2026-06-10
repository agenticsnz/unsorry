"""Gate B command-line interface.

Exit codes: 0 clean, 1 violations found, 2 internal/usage error.
"""
from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone

from .records import parse_utc_z
from .validator import render_human, render_json, validate_tree


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.gate_b",
        description="Gate B — deterministic hygiene validator for unsorry "
        "coordination records (ADR-003).",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    validate = sub.add_parser("validate", help="validate one tree root")
    validate.add_argument("root", help="tree root to validate")
    validate.add_argument(
        "--at",
        metavar="ISO8601Z",
        help="inject the validation clock, e.g. 2026-06-10T01:00:00Z "
        "(defaults to the current UTC time)",
    )
    validate.add_argument(
        "--goals-root",
        metavar="PATH",
        help="tree providing goals/ for goal-reference checks when validating "
        "a claims-only tree",
    )
    validate.add_argument(
        "--json", action="store_true", help="emit a deterministic JSON report"
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if args.at is not None:
        at = parse_utc_z(args.at)
        if at is None:
            print(
                f"error: --at '{args.at}' is not ISO-8601 UTC with Z suffix",
                file=sys.stderr,
            )
            return 2
    else:
        at = datetime.now(timezone.utc).replace(microsecond=0)

    try:
        violations = validate_tree(args.root, at=at, goals_root=args.goals_root)
    except OSError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if args.json:
        sys.stdout.write(render_json(violations, root=args.root, at=at))
    else:
        sys.stdout.write(render_human(violations))
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())
