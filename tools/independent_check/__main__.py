"""CLI for the contributor-side independent proof check (ADR-096 Phase 3a).

Usage (called by swarm/agent.sh when UNSORRY_INDEPENDENT_CHECK is on):
  python3 -m tools.independent_check --module Unsorry.Foo \
    --lean4export-cmd "lake env /path/to/lean4export" --nanoda-cmd /path/to/nanoda_bin

ADVISORY: exit 0 when the check ran (whatever the verdict) or was cleanly skipped;
exit 2 only on a tooling/usage failure. It NEVER fails the caller on a proof
disagreement — that is surfaced in the verdict line (and as a warning) for audit,
never as a block. Soundness rests on ADR-049's p=1 Lean gate in CI, unchanged.
"""
from __future__ import annotations

import argparse
import json
import shlex
import sys
from pathlib import Path

from tools.independent_check import check_proof, verdict_line


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--module", required=True, help="the proved library module, e.g. Unsorry.Foo")
    p.add_argument("--root", type=Path, default=Path("."))
    p.add_argument("--lean4export-cmd", default="lake env lean4export")
    p.add_argument("--nanoda-cmd", default="nanoda_bin")
    p.add_argument("--export-dir", type=Path, default=Path("independent-check-exports"))
    p.add_argument("--timeout", type=float, default=300.0)
    p.add_argument("--negative-control", action="store_true")
    p.add_argument("--json", action="store_true", help="emit the verdict dict as JSON")
    args = p.parse_args(argv)

    try:
        verdict = check_proof(
            args.root,
            args.module,
            shlex.split(args.lean4export_cmd),
            shlex.split(args.nanoda_cmd),
            args.export_dir,
            timeout=args.timeout,
            negative_control=args.negative_control,
        )
    except Exception as exc:  # tooling failure — advisory, never crash the prove loop
        print(f"independent-check: {args.module} — tooling error: {exc}", file=sys.stderr)
        return 2

    line = verdict_line(verdict)
    print(json.dumps(verdict) if args.json else line, flush=True)
    # A disagreement (nanoda rejected a locally-accepted proof) is surfaced loudly
    # but does NOT fail — advisory only.
    if verdict["status"] not in ("ok", "no-decls", "export-failed"):
        print(f"::warning::independent-check disagreement — {line}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
