#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one consecutive-product
divisibility goal ``(k! : ℤ) ∣ n·(n+1)·…·(n+k−1)`` (see :mod:`_artifact`).

The proof is the ``gzmod`` pattern: a finite ``ZMod k!`` case check
(``∀ m, m·(m+1)·… = 0`` by kernel ``decide``) lifted to ``ℤ`` through
``ZMod.intCast_zmod_eq_zero_iff_dvd`` — no ``native_decide``, so the axiom
profile stays ``[propext, Classical.choice, Quot.sound]``.

Run from the repository root::

    python3 tools/seedkit/mkfiles_factdvd.py <k>
"""
from __future__ import annotations

import math
import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_factdvd  # noqa: E402


def write_goal(k, solver=None, agent=None, date=None):
    """Write the 5 artifact files for run length ``k`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    fact = math.factorial(k)
    prod_n = gen_factdvd.product("n", k)
    prod_m = gen_factdvd.product("m", k)
    gid = gen_factdvd.goal_id(k)
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℤ) : ({fact} : ℤ) ∣ {prod_n} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"set_option maxRecDepth 40000 in\n"
        f"/-- Goal `{gid}`: `{fact} ∣` the product of {k} consecutive integers "
        f"`{prod_n}`,\n"
        f"by a finite `ZMod {fact}` case check lifted through "
        f"`ZMod.intCast_zmod_eq_zero_iff_dvd`. -/\n"
        f"theorem {name} (n : ℤ) : ({fact} : ℤ) ∣ {prod_n} := by\n"
        f"  have h : ∀ m : ZMod {fact}, {prod_m} = 0 := by decide\n"
        f"  have hz : (({prod_n} : ℤ) : ZMod {fact}) = 0 := by push_cast; exact h _\n"
        f"  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd ({prod_n}) {fact}).mp hz\n"
        f"  exact_mod_cast hdvd\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=(
            f"The product of {k} consecutive integers starting at n is divisible "
            f"by {k}! = {fact}, for every integer n."
        ),
        source="self-seeded consecutive-product divisibility family.",
        reference=f"provable by a finite `ZMod {fact}` case check.",
        difficulty=3,
        delta="0.60",
        model="template-zmod-decide",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 1:
        sys.exit("usage: mkfiles_factdvd.py <k>")
    print(write_goal(int(argv[0])))


if __name__ == "__main__":
    main()
