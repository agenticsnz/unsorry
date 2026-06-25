#!/usr/bin/env python3
"""Enumerate consecutive-product divisibility goals and emit their metadata.

The product of ``k`` consecutive integers is divisible by ``k!``::

    ∀ n : ℤ, (k! : ℤ) ∣ n·(n+1)·…·(n+k−1)

This holds for every integer ``n`` (a classic fact), so — like the ``gzmod``
divisibility family — it is *true by an exhaustive residue check*: ``k! ∣ ∏`` iff
the product is ``0`` for every residue in ``ZMod k!``, which the proof discharges
by kernel ``decide`` (`mkfiles_factdvd`). The enumeration ranges ``k``; goal ids
already present under ``goals/`` are skipped. Output is one pipe-delimited line
per goal::

    k|id|name|Module|sha

``k`` is capped so the ``ZMod k!`` ``decide`` stays kernel-tractable (``k! ≤``
a few thousand). Run from the repository root.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import tools.lean_sig as LS  # noqa: E402

from _words import WORDS  # noqa: E402


def goal_id(k: int) -> str:
    return f"factorial-dvd-consec-{WORDS[k]}"


def product(var: str, k: int) -> str:
    """``var·(var+1)·…·(var+k−1)`` as a Lean expression."""
    terms = [var] + [f"({var} + {i})" for i in range(1, k)]
    return " * ".join(terms)


def statement_lean(k: int, name: str) -> str:
    fact = math.factorial(k)
    return (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℤ) : ({fact} : ℤ) ∣ {product('n', k)} := by\n"
        f"  sorry\n"
    )


def candidates(ks, limit, existing):
    out = []
    for k in ks:
        if k not in WORDS:
            continue
        gid = goal_id(k)
        if gid in existing:
            continue
        out.append(k)
        if limit and len(out) >= limit:
            return out
    return out


def run(ks=None, limit=5, goals_dir="goals"):
    if ks is None:
        ks = range(2, 7)  # k! = 2..720, kernel-decide tractable
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for k in candidates(ks, limit, existing):
        gid = goal_id(k)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(k, name))
        print(f"{k}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--ks", default=None,
                   help="comma-separated consecutive-run lengths (default: 2..6)")
    p.add_argument("--limit", type=int, default=5,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    ks = ([int(x) for x in args.ks.split(",") if x.strip()]
          if args.ks else None)
    run(ks, args.limit)


if __name__ == "__main__":
    main()
