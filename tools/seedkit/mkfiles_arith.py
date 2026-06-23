#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one arithmetic-series goal
``2·∑ k ∈ range n, (k + c) = n·(n−1) + 2·c·n`` (see :mod:`_artifact`).

The proof is induction on ``n``: base ``simp``; the step rewrites with
``Finset.sum_range_succ`` and ``mul_add``, applies the inductive hypothesis,
then ``push_cast; ring``. Axiom profile stays
``[propext, Classical.choice, Quot.sound]``.

Run from the repository root::

    python3 tools/seedkit/mkfiles_arith.py <c>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_arith  # noqa: E402


def write_goal(c, solver=None, agent=None, date=None):
    """Write the 5 artifact files for offset ``c`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    lhs, rhs = gen_arith.sides(c)
    gid = gen_arith.goal_id(c)
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"/-- Goal `{gid}`: arithmetic-series closed form, "
        f"by induction on `n`. -/\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  induction n with\n"
        f"  | zero => simp\n"
        f"  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=(
            f"An arithmetic-series closed form (offset {c}): twice the sum over "
            f"k in range n of (k + {c}) equals n·(n−1) + 2·{c}·n."
        ),
        source="self-seeded arithmetic-series identity family.",
        reference="Gauss summation; proved by induction on n.",
        difficulty=3,
        delta="0.55",
        model="template-induction-ring",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 1:
        sys.exit("usage: mkfiles_arith.py <c>")
    print(write_goal(int(argv[0])))


if __name__ == "__main__":
    main()
