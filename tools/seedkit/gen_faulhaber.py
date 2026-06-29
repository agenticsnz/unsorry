#!/usr/bin/env python3
"""Enumerate geometric-series and Faulhaber closed-form goals and emit metadata.

Two related closed-form families over ``∑ k ∈ Finset.range n``, parametrised by
an integer ``v``:

* ``geometric`` — ``(v − 1)·∑ k ∈ range n, v^k = v^n − 1``.
* ``faulhaber-{square,cube,quartic,quintic}`` — the power sum ``∑ k^p`` scaled by
  the integer denominator that clears the Faulhaber rational, e.g.
  ``6·v·∑ k^2 = v·(n·(n−1)·(2n−1))``.

Both are *true by construction* (geometric telescoping / the integer Faulhaber
identities), so there is no truth-filter; the enumeration ranges ``v``. The
proof is induction on ``n`` with ``Finset.sum_range_succ`` then ``ring``
(`mkfiles_faulhaber`). Goal ids already present under ``goals/`` are skipped.
Output is one pipe-delimited line per goal::

    family|v|id|name|Module|sha

Run from the repository root.

.. note::
   ``sides`` runs **only** under ``__main__`` here, never at import — the writer
   imports this module for :data:`FAMILIES` and :func:`sides` and must not have
   the enumeration fire as a side effect (the import-safety contract enforced by
   ``tools/seedkit/tests/test_import_safe.py``).
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import tools.lean_sig as LS  # noqa: E402

from _words import WORDS  # noqa: E402

# family -> closed-form descriptor. "geo" telescopes; "fau" power sums carry the
# integer-clearing coefficient and the closed-form polynomial in n.
FAMILIES = {
    "geometric": {"kind": "geo"},
    "faulhaber-square": {
        "kind": "fau", "p": 2, "coeff": 6,
        "poly": "(n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)"},
    "faulhaber-cube": {
        "kind": "fau", "p": 3, "coeff": 4,
        "poly": "((n : ℤ) * ((n : ℤ) - 1)) ^ 2"},
    "faulhaber-quartic": {
        "kind": "fau", "p": 4, "coeff": 30,
        "poly": "(n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) "
                "* (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)"},
    "faulhaber-quintic": {
        "kind": "fau", "p": 5, "coeff": 12,
        "poly": "(n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 "
                "* (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)"},
}


def sides(family: str, v: int):
    """``(gid, lhs, rhs)`` for the closed form at parameter ``v``."""
    cfg = FAMILIES[family]
    if cfg["kind"] == "geo":
        gid = f"geometric-series-ratio-{WORDS[v]}"
        lhs = f"(({v} : ℤ) - 1) * ∑ k ∈ Finset.range n, ({v} : ℤ) ^ k"
        rhs = f"({v} : ℤ) ^ n - 1"
    else:
        gid = f"{family}-sum-coeff-{WORDS[v]}"
        lhs = f"{cfg['coeff'] * v} * ∑ k ∈ Finset.range n, (k : ℤ) ^ {cfg['p']}"
        rhs = f"{v} * ({cfg['poly']})"
    return gid, lhs, rhs


def statement_lean(family: str, v: int, name: str) -> str:
    _gid, lhs, rhs = sides(family, v)
    return (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )


def candidates(family, values, limit, existing):
    out = []
    for v in values:
        if v not in WORDS:
            continue
        gid, _lhs, _rhs = sides(family, v)
        if gid in existing:
            continue
        out.append(v)
        if limit and len(out) >= limit:
            return out
    return out


def run(family, values=None, limit=5, goals_dir="goals"):
    if values is None:
        values = range(2, max(WORDS) + 1)
    existing = {
        os.path.splitext(f)[0]
        for f in os.listdir(goals_dir)
        if f.endswith(".lean")
    }
    for v in candidates(family, values, limit, existing):
        gid, _lhs, _rhs = sides(family, v)
        name = gid.replace("-", "_")
        sha = LS.statement_sha(statement_lean(family, v, name))
        print(f"{family}|{v}|{gid}|{name}|{LS.camel_name(gid)}|{sha}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--family", required=True, choices=sorted(FAMILIES),
                   help="closed-form family to enumerate")
    p.add_argument("--values", default=None,
                   help="comma-separated parameters v (default: 2..26)")
    p.add_argument("--limit", type=int, default=5,
                   help="max goals to emit per invocation (0 = unlimited)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    values = ([int(x) for x in args.values.split(",") if x.strip()]
              if args.values else None)
    run(args.family, values, args.limit)


if __name__ == "__main__":
    main()
