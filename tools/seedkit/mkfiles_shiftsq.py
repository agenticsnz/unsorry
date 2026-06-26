#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one shifted-square-sum goal
``6·∑ k ∈ range n, (k + c)^2 = n(n−1)(2n−1) + 6c·n(n−1) + 6n·c^2``
(see :mod:`_artifact`).

The proof is induction on ``n``: base ``simp``; the step rewrites with
``Finset.sum_range_succ`` and ``mul_add``, applies the inductive hypothesis,
then ``push_cast; ring``.

Run from the repository root::

    python3 tools/seedkit/mkfiles_shiftsq.py <c>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_shiftsq  # noqa: E402


def write_goal(c, solver=None, agent=None, date=None):
    """Write the 5 artifact files for offset ``c`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    lhs, rhs = gen_shiftsq.sides(c)
    gid = gen_shiftsq.goal_id(c)
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"/-- Goal `{gid}`: shifted-square-sum closed form, "
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
            f"A shifted-square-sum closed form (offset {c}): six times the sum "
            f"over k in range n of (k + {c})² has the stated cubic closed form."
        ),
        source="self-seeded shifted-square-sum identity family.",
        reference="follows from the square-pyramidal sum; proved by induction on n.",
        difficulty=1,
        delta="0.70",
        model="ring",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 1:
        sys.exit("usage: mkfiles_shiftsq.py <c>")
    print(write_goal(int(argv[0])))


if __name__ == "__main__":
    main()
