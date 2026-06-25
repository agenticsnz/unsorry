#!/usr/bin/env python3
"""Enumerate telescoping power-sum closed-form goals and emit their metadata.

For a fixed exponent ``p`` and coefficient ``a``, the summand is ``a``·the
binomial expansion of ``(k+1)^p − k^p``; summed over ``k ∈ range n`` it
telescopes to ``a·n^p``::

    ∀ n : ℕ, ∑ k ∈ Finset.range n, (a·((k+1)^p − k^p)) = a·n^p

These identities are *true by construction* (telescoping), so — unlike the
residue/divisibility families — there is no truth-filter to apply; the
enumeration just ranges the coefficient. The proof is induction on ``n`` with
``Finset.sum_range_succ`` then ``ring`` (`mkfiles_telescoping`). Goal ids
already present under ``goals/`` are skipped. Output is one pipe-delimited line
per goal::

    shape|a|id|name|Module|sha

Shapes (``--shape``): square (p=2), cube (p=3), quartic (p=4), quintic (p=5),
sextic (p=6).

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

# shape -> (exponent p, summand template in coefficient {a}); the summand is the
# expansion of (k+1)^p - k^p, so the telescoped sum is a·n^p.
SHAPES = {
    "square": (2, "2 * {a} * (k : ℤ) + {a}"),
    "cube": (3, "{a} * (3 * (k : ℤ) ^ 2 + 3 * (k : ℤ) + 1)"),
    "quartic": (4, "{a} * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)"),
    "quintic": (5, "{a} * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 "
                   "+ 5 * (k : ℤ) + 1)"),
    "sextic": (6, "{a} * (6 * (k : ℤ) ^ 5 + 15 * (k : ℤ) ^ 4 + 20 * (k : ℤ) ^ 3 "
                  "+ 15 * (k : ℤ) ^ 2 + 6 * (k : ℤ) + 1)"),
}


def goal_id(shape: str, a: int) -> str:
    return f"telescoping-{shape}-sum-coeff-{WORDS[a]}"


def sides(shape: str, a: int):
    """``(lhs, rhs)`` Lean expressions for the identity at coefficient ``a``."""
    p, summ = SHAPES[shape]
    lhs = f"∑ k ∈ Finset.range n, ({summ.format(a=a)})"
    rhs = f"{a} * (n : ℤ) ^ {p}"
    return lhs, rhs


def statement_lean(shape: str, a: int, name: str) -> str:
    lhs, rhs = sides(shape, a)
    return (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )


def candidates(shape, coeffs, limit, existing):
    out = []
    for a in coeffs:
        if a not in WORDS:
            continue
        gid = goal_id(shape, a)
        if gid in existing:
            continue
        out.append(a)
        if limit and len(out) >= limit:
            return out
    return out


def run(shape, coeffs=None, limit=5, goals_dir="goals"):
    if coeffs is None:
        coeffs = range(1, max(WORDS) + 1)
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for a in candidates(shape, coeffs, limit, existing):
        gid = goal_id(shape, a)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(shape, a, name))
        print(f"{shape}|{a}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--shape", required=True, choices=sorted(SHAPES),
                   help="power-sum shape to enumerate")
    p.add_argument("--coeffs", default=None,
                   help="comma-separated coefficients (default: 1..30)")
    p.add_argument("--limit", type=int, default=5,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    coeffs = ([int(x) for x in args.coeffs.split(",") if x.strip()]
              if args.coeffs else None)
    run(args.shape, coeffs, args.limit)


if __name__ == "__main__":
    main()
