#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one divisibility goal
``M | n^a - n^b`` (see :mod:`_artifact` for the shared file shapes).

The proof is a finite ``ZMod M`` case check lifted to ``ℤ`` through
``ZMod.intCast_zmod_eq_zero_iff_dvd`` using kernel ``decide`` (no
``native_decide``), so the axiom profile stays
``[propext, Classical.choice, Quot.sound]``.

Run from the repository root::

    python3 tools/seedkit/mkfiles.py <M> <a> <b>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.getcwd())  # repo root, for `import tools.lean_sig`
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # sibling helpers
import _artifact  # noqa: E402
import _words  # noqa: E402

# Narrow exponent range (3..20); the widened writer extends this table.
WORDS = {k: _words.WORDS[k] for k in range(3, 21)}


def write_goal(M, a, b, words=WORDS, solver=None, agent=None, date=None):
    """Write the 5 artifact files for ``(M, a, b)`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    gid = f"gzmod-{M}-pow-{words[a]}-sub-pow-{words[b]}"
    name = gid.replace("-", "_")

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℤ) : ({M} : ℤ) ∣ n ^ {a} - n ^ {b} := by\n"
        f"  sorry\n"
    )

    proof = (
        f"import Mathlib\n\n"
        f"set_option maxRecDepth 40000 in\n"
        f"/-- Goal `{gid}`: `{M} ∣ n^{a} - n^{b}` over `ℤ`, by a finite "
        f"`ZMod {M}` case check\n"
        f"lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. "
        f"See `library/index/`. -/\n"
        f"theorem {name} (n : ℤ) : ({M} : ℤ) ∣ n ^ {a} - n ^ {b} := by\n"
        f"  have h : ∀ m : ZMod {M}, m ^ {a} - m ^ {b} = 0 := by decide\n"
        f"  have hz : ((n ^ {a} - n ^ {b} : ℤ) : ZMod {M}) = 0 := by "
        f"push_cast; exact h _\n"
        f"  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd "
        f"(n ^ {a} - n ^ {b}) {M}).mp hz\n"
        f"  exact_mod_cast hdvd\n"
    )

    return _artifact.write_artifacts(
        gid=gid,
        name=name,
        goal_lean=goal_lean,
        proof=proof,
        summary=f"{M} divides n to the {a} minus n to the {b}, for every integer n.",
        source="self-seeded polynomial-divisibility identity family.",
        reference=f"provable by a finite `ZMod {M}` case check.",
        difficulty=1,
        delta="0.60",
        model="decide",
        solver=solver,
        agent=agent,
        date=date,
    )


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 3:
        sys.exit("usage: mkfiles.py <M> <a> <b>")
    M, a, b = (int(x) for x in argv[:3])
    print(write_goal(M, a, b))


if __name__ == "__main__":
    main()
