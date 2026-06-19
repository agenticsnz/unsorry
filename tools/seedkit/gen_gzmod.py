#!/usr/bin/env python3
"""Enumerate valid divisibility goals ``M | n^a - n^b`` over ``ℤ`` and emit the
metadata needed to materialise them.

For each candidate ``(M, a, b)`` the statement is *proved true* by an exhaustive
residue check (``all(pow(m, a, M) == pow(m, b, M) for m in range(M))``) before it
is emitted, so a false statement is never produced. Goal ids already present
under ``goals/`` are skipped. Output is one pipe-delimited line per goal::

    M|a|b|id|name|Module|sha

A modulus ``M`` only admits a valid ``(a, b)`` when its Carmichael ``λ(M)``
divides the exponent gap ``a - b``; the ``--dmax`` cap therefore bounds which
moduli are productive. Run from the repository root.
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.getcwd())
import tools.lean_sig as LS  # noqa: E402

WORDS = {
    1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six",
    7: "seven", 8: "eight", 9: "nine", 10: "ten", 11: "eleven", 12: "twelve",
    13: "thirteen", 14: "fourteen", 15: "fifteen", 16: "sixteen",
    17: "seventeen", 18: "eighteen", 19: "nineteen", 20: "twenty",
    21: "twentyone", 22: "twentytwo", 23: "twentythree", 24: "twentyfour",
    25: "twentyfive", 26: "twentysix", 27: "twentyseven", 28: "twentyeight",
    29: "twentynine", 30: "thirty",
}


def valid(M: int, a: int, b: int) -> bool:
    """True iff ``M | n^a - n^b`` for every integer ``n`` (checked on residues)."""
    return all(pow(m, a, M) == pow(m, b, M) for m in range(M))


def goal_id(M: int, a: int, b: int) -> str:
    return f"gzmod-{M}-pow-{WORDS[a]}-sub-pow-{WORDS[b]}"


def statement_lean(M: int, a: int, b: int, name: str) -> str:
    return (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℤ) : ({M} : ℤ) ∣ n ^ {a} - n ^ {b} := by\n"
        f"  sorry\n"
    )


def candidates(mods, bmax, dmax, amax, limit, existing):
    out, seen = [], set()
    for M in mods:
        for b in range(3, bmax + 1):
            for d in range(2, dmax + 1):
                a = b + d
                if a > amax or a not in WORDS or b not in WORDS:
                    continue
                if not valid(M, a, b):
                    continue
                gid = goal_id(M, a, b)
                if gid in existing or gid in seen:
                    continue
                seen.add(gid)
                out.append((M, a, b))
                if limit and len(out) >= limit:
                    return out
    return out


def run(mods, bmax=8, dmax=12, amax=20, limit=14, goals_dir="goals"):
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for M, a, b in candidates(mods, bmax, dmax, amax, limit, existing):
        gid = goal_id(M, a, b)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(M, a, b, name))
        print(f"{M}|{a}|{b}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--mods", required=True,
                   help="comma-separated moduli, e.g. 156,160")
    p.add_argument("--bmax", type=int, default=8, help="max base exponent b")
    p.add_argument("--dmax", type=int, default=12, help="max exponent gap a-b")
    p.add_argument("--amax", type=int, default=20, help="max exponent a")
    p.add_argument("--limit", type=int, default=14,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    mods = [int(x) for x in args.mods.split(",") if x.strip()]
    run(mods, args.bmax, args.dmax, args.amax, args.limit)


if __name__ == "__main__":
    main()
