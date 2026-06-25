#!/usr/bin/env python3
"""Enumerate alternating-geometric-series goals and emit their metadata.

For a ratio magnitude ``r`` the alternating geometric series telescopes::

    ∀ n : ℕ, (r + 1) * ∑ k ∈ Finset.range n, (-r)^k = 1 - (-r)^n

True by construction (geometric telescoping with ratio ``-r``), so there is no
truth-filter; the enumeration ranges ``r``. The proof is induction on ``n`` with
``Finset.sum_range_succ`` then ``ring`` (`mkfiles_altgeom`). Goal ids already
present under ``goals/`` are skipped. Output is one pipe-delimited line per
goal::

    r|id|name|Module|sha

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


def goal_id(r: int) -> str:
    return f"alt-geometric-ratio-{WORDS[r]}"


def sides(r: int):
    lhs = f"(({r} : ℤ) + 1) * ∑ k ∈ Finset.range n, (-({r} : ℤ)) ^ k"
    rhs = f"1 - (-({r} : ℤ)) ^ n"
    return lhs, rhs


def statement_lean(r: int, name: str) -> str:
    lhs, rhs = sides(r)
    return (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )


def candidates(values, limit, existing):
    out = []
    for r in values:
        if r not in WORDS:
            continue
        gid = goal_id(r)
        if gid in existing:
            continue
        out.append(r)
        if limit and len(out) >= limit:
            return out
    return out


def run(values=None, limit=5, goals_dir="goals"):
    if values is None:
        values = range(1, max(WORDS) + 1)
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for r in candidates(values, limit, existing):
        gid = goal_id(r)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(r, name))
        print(f"{r}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--values", default=None,
                   help="comma-separated ratio magnitudes r (default: 1..80)")
    p.add_argument("--limit", type=int, default=5,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    values = ([int(x) for x in args.values.split(",") if x.strip()]
              if args.values else None)
    run(values, args.limit)


if __name__ == "__main__":
    main()
