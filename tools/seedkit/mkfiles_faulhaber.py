#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one geometric-series or Faulhaber
closed-form goal (see :mod:`_artifact` and :mod:`gen_faulhaber`).

The proof is induction on ``n``: base case ``simp``; the step rewrites with
``Finset.sum_range_succ`` and ``mul_add``, applies the inductive hypothesis,
then closes with ``ring`` (the Faulhaber families need a ``push_cast`` first to
move the ``ℕ → ℤ`` cast inward). Axiom profile stays
``[propext, Classical.choice, Quot.sound]``.

Run from the repository root::

    python3 tools/seedkit/mkfiles_faulhaber.py <family> <v>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_faulhaber  # noqa: E402


def write_goal(family, v, solver=None, agent=None, date=None):
    """Write the 5 artifact files for ``(family, v)`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    cfg = gen_faulhaber.FAMILIES[family]
    gid, lhs, rhs = gen_faulhaber.sides(family, v)
    name = gid.replace("-", "_")
    is_geo = cfg["kind"] == "geo"
    extra = "" if is_geo else "push_cast; "
    desc = (f"geometric series with ratio {v}" if is_geo
            else f"Faulhaber power sum (degree {cfg['p']}, coefficient {v})")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"/-- Goal `{gid}`: a {desc} closed form, by induction on `n`. -/\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  induction n with\n"
        f"  | zero => simp\n"
        f"  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; {extra}ring\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=(
            f"A {desc} closed form: the finite sum over k in range n has the "
            f"stated closed form."
        ),
        source="self-seeded finite-sum closed-form family.",
        reference="proved by induction on n with `ring`.",
        difficulty=1,
        delta="0.85",
        model="ring",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 2:
        sys.exit("usage: mkfiles_faulhaber.py <family> <v>")
    family = argv[0]
    v = int(argv[1])
    print(write_goal(family, v))


if __name__ == "__main__":
    main()
