"""CLI for the statement-fidelity normalizer + differ (run from repo root).

    python3 -m tools.fidelity normalize <stmt-or-file>
    python3 -m tools.fidelity sha <stmt-or-file>
    python3 -m tools.fidelity diff <a> <b> [--json]

<stmt-or-file> may be a raw AISP statement, a path to a file (a ``.aisp``
translation record has its ``stmt≜…`` auto-extracted; any other file is read
as a raw statement), or ``-`` for stdin.

Exit codes: 0 success / fidelity match · 1 fidelity mismatch · 2 usage or
input error.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .extract import ExtractError, extract_stmt, statement_from_source
from .normalize import first_divergence, line_sha, normalize


class InputError(ValueError):
    """The <stmt-or-file> argument could not be resolved to a statement."""


def resolve_statement(arg: str) -> str:
    """Resolve a <stmt-or-file> CLI argument to a raw statement."""
    if arg == "-":
        return statement_from_source(sys.stdin.read())
    path = Path(arg)
    if path.is_file():
        text = path.read_text(encoding="utf-8")
        if path.suffix == ".aisp":
            return extract_stmt(text)  # records must carry a ⟦Σ:Stmt⟧ block
        return statement_from_source(text)
    # Guard against silently normalizing a typo'd filename as a "statement":
    # statements in our subset never look like paths.
    if "/" in arg or arg.endswith((".aisp", ".txt")):
        raise InputError(f"file not found: {arg}")
    return arg


def _print_mismatch(norm_a: str, norm_b: str, as_json: bool) -> None:
    index = first_divergence(norm_a, norm_b)
    assert index is not None  # only called on mismatch
    char_a = norm_a[index] if index < len(norm_a) else None
    char_b = norm_b[index] if index < len(norm_b) else None
    if as_json:
        payload = {
            "match": False,
            "index": index,
            "a": {"normalized": norm_a, "sha": line_sha(norm_a), "char": char_a},
            "b": {"normalized": norm_b, "sha": line_sha(norm_b), "char": char_b},
        }
        print(json.dumps(payload, ensure_ascii=False))
        return
    desc_a = repr(char_a) if char_a is not None else "<end of statement>"
    desc_b = repr(char_b) if char_b is not None else "<end of statement>"
    print(f"MISMATCH at char {index}: a has {desc_a}, b has {desc_b}")
    print(f"a: {norm_a}")
    print(f"b: {norm_b}")
    print("   " + "·" * index + "^")
    print(f"sha a={line_sha(norm_a)}")
    print(f"sha b={line_sha(norm_b)}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.fidelity",
        description="Statement-fidelity normalizer + differ (SPEC-003-C).",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_norm = sub.add_parser("normalize", help="print the normalized statement")
    p_norm.add_argument("source", help="statement, file path, or - for stdin")

    p_sha = sub.add_parser("sha", help="print the 64-hex content address")
    p_sha.add_argument("source", help="statement, file path, or - for stdin")

    p_diff = sub.add_parser("diff", help="compare two statements after normalization")
    p_diff.add_argument("a", help="statement, file path, or - for stdin")
    p_diff.add_argument("b", help="statement, file path, or - for stdin")
    p_diff.add_argument("--json", action="store_true", help="machine-readable output")

    args = parser.parse_args(argv)
    try:
        if args.command == "normalize":
            print(normalize(resolve_statement(args.source)))
            return 0
        if args.command == "sha":
            print(line_sha(normalize(resolve_statement(args.source))))
            return 0
        # diff
        norm_a = normalize(resolve_statement(args.a))
        norm_b = normalize(resolve_statement(args.b))
        if norm_a == norm_b:
            sha = line_sha(norm_a)
            if args.json:
                payload = {"match": True, "sha": sha, "normalized": norm_a}
                print(json.dumps(payload, ensure_ascii=False))
            else:
                print(f"MATCH sha={sha}")
            return 0
        _print_mismatch(norm_a, norm_b, args.json)
        return 1
    except (ExtractError, InputError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
