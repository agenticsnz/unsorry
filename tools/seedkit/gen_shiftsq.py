#!/usr/bin/env python3
"""Enumerate shifted-square-sum closed-form goals and emit their metadata.

For an offset ``c`` the sum of ``(k + c)^2`` over ``k ∈ range n`` has the closed
form (cleared of its ``/6``)::

    ∀ n : ℕ, 6 * ∑ k ∈ Finset.range n, (k + c)^2
           = n·(n−1)·(2n−1) + 6·c·n·(n−1) + 6·n·c^2

True by construction, so there is no truth-filter; the enumeration ranges ``c``.
The proof is induction on ``n`` with ``Finset.sum_range_succ`` then ``ring``
(`mkfiles_shiftsq`). Goal ids already present under ``goals/`` are skipped.
Output is one pipe-delimited line per goal::

    c|id|name|Module|sha

Run from the repository root.
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import tools.lean_sig as LS  # noqa: E402

from _words import WORDS  # noqa: E402


def goal_id(c: int) -> str:
    return f"shift-square-sum-coeff-{WORDS[c]}"


def sides(c: int):
    lhs = f"6 * ∑ k ∈ Finset.range n, ((k : ℤ) + {c}) ^ 2"
    rhs = (f"(n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) "
           f"+ 6 * {c} * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * {c} ^ 2")
    return lhs, rhs


def statement_lean(c: int, name: str) -> str:
    lhs, rhs = sides(c)
    return (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )


def candidates(coeffs, limit, existing):
    out = []
    for c in coeffs:
        if c not in WORDS:
            continue
        gid = goal_id(c)
        if gid in existing:
            continue
        out.append(c)
        if limit and len(out) >= limit:
            return out
    return out


def run(coeffs=None, limit=5, goals_dir="goals"):
    if coeffs is None:
        coeffs = range(1, max(WORDS) + 1)
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for c in candidates(coeffs, limit, existing):
        gid = goal_id(c)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(c, name))
        print(f"{c}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--coeffs", default=None,
                   help="comma-separated offsets (default: 1..80)")
    p.add_argument("--limit", type=int, default=5,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    coeffs = ([int(x) for x in args.coeffs.split(",") if x.strip()]
              if args.coeffs else None)
    run(coeffs, args.limit)


if __name__ == "__main__":
    main()
