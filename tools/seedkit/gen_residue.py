#!/usr/bin/env python3
"""Enumerate valid ZMod residue non-membership goals and emit their metadata.

For a family of ``n`` integer variables each raised to a fixed degree ``d``, a
goal asserts that the sum is *never* a given residue ``r`` modulo ``m``::

    ∀ a b … : ℤ, ((a^d + b^d + … : ℤ) : ZMod m) ≠ r

Each candidate ``(m, r)`` is *proved true* before emission by computing the full
set of attainable residues ``{ Σ xᵢ^d mod m }`` and keeping only ``r`` **not** in
it (and ``1 ≤ r < m``), so a false statement is never produced. The proof itself
is a finite ``ZMod m`` case check (`mkfiles_residue`). Goal ids already present
under ``goals/`` are skipped. Output is one pipe-delimited line per goal::

    family|m|r|id|name|Module|sha

Families (``--family``):
  sum-two-squares   2 vars, degree 2
  sum-three-squares 3 vars, degree 2
  sum-two-cubes     2 vars, degree 3

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

# family -> (variable count, exponent degree, default modulus ceiling)
FAMILIES = {
    "sum-two-squares": (2, 2, 24),
    "sum-three-squares": (3, 2, 17),
    "sum-two-cubes": (2, 3, 24),
}
_VARS = ["a", "b", "c"]


def residues(m: int, nvars: int, deg: int) -> set[int]:
    """The set of residues mod ``m`` attainable as a sum of ``nvars`` ``deg``-th
    powers — the image is closed under each variable independently, so it is the
    ``nvars``-fold sumset of ``{x^deg mod m}``."""
    powers = {pow(x, deg, m) for x in range(m)}
    reach = {0}
    for _ in range(nvars):
        reach = {(s + p) % m for s in reach for p in powers}
    return reach


def goal_id(family: str, m: int, r: int) -> str:
    return f"{family}-zmod-{WORDS[m]}-ne-{WORDS[r]}"


def statement_lean(family: str, m: int, r: int, name: str) -> str:
    nvars, deg, _ = FAMILIES[family]
    vs = _VARS[:nvars]
    expr = " + ".join(f"{v} ^ {deg}" for v in vs)
    return (
        f"import Mathlib\n\n"
        f"theorem {name} ({' '.join(vs)} : ℤ) : "
        f"((({expr} : ℤ)) : ZMod {m}) ≠ {r} := by\n"
        f"  sorry\n"
    )


def candidates(family, mhi, limit, existing):
    nvars, deg, _ = FAMILIES[family]
    out = []
    for m in range(3, mhi + 1):
        if m not in WORDS:
            continue
        reach = residues(m, nvars, deg)
        for r in range(1, m):
            if r in reach or r not in WORDS:
                continue
            gid = goal_id(family, m, r)
            if gid in existing:
                continue
            out.append((m, r))
            if limit and len(out) >= limit:
                return out
    return out


def run(family, mhi=None, limit=8, goals_dir="goals"):
    if mhi is None:
        mhi = FAMILIES[family][2]
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for m, r in candidates(family, mhi, limit, existing):
        gid = goal_id(family, m, r)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(family, m, r, name))
        print(f"{family}|{m}|{r}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--family", required=True, choices=sorted(FAMILIES),
                   help="residue family to enumerate")
    p.add_argument("--mhi", type=int, default=None,
                   help="modulus ceiling (default: family-specific)")
    p.add_argument("--limit", type=int, default=8,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    run(args.family, args.mhi, args.limit)


if __name__ == "__main__":
    main()
