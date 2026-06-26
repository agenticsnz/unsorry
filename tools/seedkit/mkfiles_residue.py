#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one ZMod residue goal
``∀ a b … : ℤ, ((a^d + … : ℤ) : ZMod m) ≠ r`` (see :mod:`_artifact`).

The proof casts the integer sum into ``ZMod m`` (``push_cast; ring``),
``generalize``s each cast variable to a free ``ZMod m`` element, and discharges
the finite goal with kernel ``decide`` — so the axiom profile stays
``[propext, Classical.choice, Quot.sound]`` (no ``native_decide``).

Run from the repository root::

    python3 tools/seedkit/mkfiles_residue.py <family> <m> <r>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import gen_residue  # noqa: E402
from _words import WORDS  # noqa: E402

# Human-readable phrase per family, for the backlog description.
_DESC = {
    "sum-two-squares": "two squares",
    "sum-three-squares": "three squares",
    "sum-two-cubes": "two cubes",
}


def write_goal(family, m, r, solver=None, agent=None, date=None):
    """Write the 5 artifact files for ``(family, m, r)`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    nvars, deg, _ = gen_residue.FAMILIES[family]
    vs = gen_residue._VARS[:nvars]
    newv = ["x", "y", "z"][:nvars]
    expr = " + ".join(f"{v} ^ {deg}" for v in vs)
    zexpr = " + ".join(f"({v} : ZMod {m}) ^ {deg}" for v in vs)
    gens = "\n".join(
        f"  generalize ({v} : ZMod {m}) = {w}" for v, w in zip(vs, newv)
    )

    gid = f"{family}-zmod-{WORDS[m]}-ne-{WORDS[r]}"
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} ({' '.join(vs)} : ℤ) : "
        f"((({expr} : ℤ)) : ZMod {m}) ≠ {r} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"set_option maxRecDepth 8000 in\n"
        f"/-- Goal `{gid}`: over `ℤ`, `{expr}` is never `{r}` in `ZMod {m}`,\n"
        f"by reducing the integer cast to `ZMod {m}` and a finite case check. -/\n"
        f"theorem {name} ({' '.join(vs)} : ℤ) : "
        f"((({expr} : ℤ)) : ZMod {m}) ≠ {r} := by\n"
        f"  have h : ((({expr} : ℤ)) : ZMod {m}) = {zexpr} := by push_cast; ring\n"
        f"  rw [h]\n"
        f"{gens}\n"
        f"  revert {' '.join(newv)}\n"
        f"  decide\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=(
            f"For all integers {', '.join(vs)}, the sum {expr} is never "
            f"congruent to {r} modulo {m}."
        ),
        source=f"self-seeded power-residue identity family ({_DESC[family]}).",
        reference=(
            f"{r} is not a sum of {_DESC[family]} modulo {m}; "
            f"provable by a finite `ZMod {m}` case check."
        ),
        difficulty=1,
        delta="0.40",
        model="decide",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 3:
        sys.exit("usage: mkfiles_residue.py <family> <m> <r>")
    family = argv[0]
    m, r = int(argv[1]), int(argv[2])
    print(write_goal(family, m, r))


if __name__ == "__main__":
    main()
