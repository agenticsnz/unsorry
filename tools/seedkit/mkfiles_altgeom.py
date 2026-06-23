#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one alternating-geometric goal
``(r + 1)·∑ k ∈ range n, (-r)^k = 1 - (-r)^n`` (see :mod:`_artifact`).

The proof is induction on ``n``: base ``simp``; the step rewrites with
``Finset.sum_range_succ`` and ``mul_add``, applies the inductive hypothesis,
then ``ring``.

Run from the repository root::

    python3 tools/seedkit/mkfiles_altgeom.py <r>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_altgeom  # noqa: E402


def write_goal(r, solver=None, agent=None, date=None):
    """Write the 5 artifact files for ratio magnitude ``r`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    lhs, rhs = gen_altgeom.sides(r)
    gid = gen_altgeom.goal_id(r)
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"/-- Goal `{gid}`: alternating geometric series (ratio -{r}) closed "
        f"form, by induction on `n`. -/\n"
        f"theorem {name} (n : ℕ) : {lhs} = {rhs} := by\n"
        f"  induction n with\n"
        f"  | zero => simp\n"
        f"  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=(
            f"An alternating geometric series closed form (ratio -{r}): "
            f"({r}+1) times the sum over k in range n of (-{r})^k equals "
            f"1 - (-{r})^n."
        ),
        source="self-seeded alternating-geometric identity family.",
        reference="geometric telescoping with ratio -r; proved by induction on n.",
        difficulty=5,
        delta="0.85",
        model="template-induction-ring",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 1:
        sys.exit("usage: mkfiles_altgeom.py <r>")
    print(write_goal(int(argv[0])))


if __name__ == "__main__":
    main()
