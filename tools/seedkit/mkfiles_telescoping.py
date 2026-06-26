#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one telescoping power-sum goal
``∑ k ∈ range n, a·((k+1)^p − k^p) = a·n^p`` (see :mod:`_artifact`).

The proof is induction on ``n``: the base case is ``simp``, the step rewrites
with ``Finset.sum_range_succ`` and the inductive hypothesis, then ``push_cast;
ring`` closes the polynomial identity. Axiom profile stays
``[propext, Classical.choice, Quot.sound]``.

Run from the repository root::

    python3 tools/seedkit/mkfiles_telescoping.py <shape> <a>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_telescoping  # noqa: E402
from _words import WORDS  # noqa: E402


def write_goal(shape, a, solver=None, agent=None, date=None):
    """Write the 5 artifact files for ``(shape, a)`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    p, _ = gen_telescoping.SHAPES[shape]
    lhs, rhs = gen_telescoping.sides(shape, a)
    gid = f"telescoping-{shape}-sum-coeff-{WORDS[a]}"
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"/-- Goal `{gid}`: telescoping power-sum closed form, "
        f"by induction on `n`. -/\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  induction n with\n"
        f"  | zero => simp\n"
        f"  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=(
            f"A telescoping power-sum closed form (coefficient {a}, exponent "
            f"{p}): the finite sum over k in range n equals {a}·n^{p}."
        ),
        source="self-seeded telescoping finite-sum identity family.",
        reference=(
            f"follows from (k+1)^{p} − k^{p} telescoping; proved by induction "
            f"on n."
        ),
        difficulty=1,
        delta="0.75",
        model="ring",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 2:
        sys.exit("usage: mkfiles_telescoping.py <shape> <a>")
    shape = argv[0]
    a = int(argv[1])
    print(write_goal(shape, a))


if __name__ == "__main__":
    main()
