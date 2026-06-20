#!/usr/bin/env python3
"""Materialise the 5-file proof artifact for one divisibility goal
``M | n^a - n^b``::

    goals/<id>.lean              the statement (with sorry)
    goals/<id>.aisp              goal record (status proved, sha, difficulty)
    backlog/<id>.md              human-readable description
    library/Unsorry/<Mod>.lean   the proof
    library/index/<sha>.aisp     index record (statement sha + provenance)

The proof is a finite ``ZMod M`` case check lifted to ``ℤ`` through
``ZMod.intCast_zmod_eq_zero_iff_dvd`` using kernel ``decide`` (no
``native_decide``), so the axiom profile stays
``[propext, Classical.choice, Quot.sound]``.

Run from the repository root::

    python3 tools/seedkit/mkfiles.py <M> <a> <b>

The provenance ``solver`` id is taken from ``$SEEDKIT_SOLVER`` (default
``anon``); the ``agent`` id from ``$SEEDKIT_AGENT`` (default ``seedkit``).
"""
from __future__ import annotations

import datetime
import os
import sys

sys.path.insert(0, os.getcwd())
import tools.lean_sig as LS  # noqa: E402

# MATHEMATICAL DOUBLE-STRUCK CAPITAL D, matching the existing AISP corpus.
_HDR = "\U0001D538" + "5"

WORDS = {
    3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight",
    9: "nine", 10: "ten", 11: "eleven", 12: "twelve", 13: "thirteen",
    14: "fourteen", 15: "fifteen", 16: "sixteen", 17: "seventeen",
    18: "eighteen", 19: "nineteen", 20: "twenty",
}


def write_goal(M, a, b, words=WORDS, solver=None, agent=None, date=None):
    """Write the 5 artifact files for ``(M, a, b)`` and return
    ``"<id>|<name>|<Module>|<sha>"``."""
    gid = f"gzmod-{M}-pow-{words[a]}-sub-pow-{words[b]}"
    name = gid.replace("-", "_")
    mod = LS.camel_name(gid)
    solver = solver or os.environ.get("SEEDKIT_SOLVER", "anon")
    agent = agent or os.environ.get("SEEDKIT_AGENT", "seedkit")
    date = date or datetime.date.today().isoformat()

    goal_lean = (
        f"import Mathlib\n\n"
        f"theorem {name} (n : ℤ) : ({M} : ℤ) ∣ n ^ {a} - n ^ {b} := by\n"
        f"  sorry\n"
    )
    sha = LS.statement_sha(goal_lean)

    goal_aisp = (
        f"{_HDR}.1.goal.{gid}@{date}\n"
        f"γ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{\n"
        f"  id≜{gid}\n"
        f"  phase≜prove\n"
        f"  status≜proved\n"
        f"  difficulty≜3\n"
        f"}}\n"
        f"⟦Σ:Source⟧{{\n"
        f"  src≜backlog/{gid}.md\n"
        f"}}\n"
        f"⟦Γ:Deps⟧{{\n"
        f"  deps≜⟨⟩\n"
        f"}}\n"
        f"⟦Λ:Artifact⟧{{\n"
        f"  lean≜goals/{gid}.lean\n"
        f"  sha≜{sha}\n"
        f"  aff≜0\n"
        f"}}\n"
        f"⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )

    backlog = (
        f"# {gid}\n\n"
        f"{M} divides n to the {a} minus n to the {b}, for every integer n.\n\n"
        f"- **Source:** self-seeded polynomial-divisibility identity family.\n"
        f"- **Reference:** provable by a finite `ZMod {M}` case check.\n"
        f"- **Difficulty:** 3\n"
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

    index = (
        f"{_HDR}.1.lemma.{sha[:12]}@{date}\n"
        f"γ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{gid}; name≜{name}}}\n"
        f"⟦Σ:Source⟧{{src≜goals/{gid}.lean}}\n"
        f"⟦Γ:Tags⟧{{tags≜⟨⟩}}\n"
        f"⟦Λ:Meta⟧{{use≜0; aff≜0}}\n"
        f"⟦Π:Provenance⟧{{solver≜{solver}; agent≜{agent}; "
        f"provider≜seedkit; model≜template-zmod-decide; attempts≜1}}\n"
        f"⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )

    os.makedirs("goals", exist_ok=True)
    os.makedirs("backlog", exist_ok=True)
    os.makedirs("library/Unsorry", exist_ok=True)
    os.makedirs("library/index", exist_ok=True)
    with open(f"goals/{gid}.lean", "w") as f:
        f.write(goal_lean)
    with open(f"goals/{gid}.aisp", "w") as f:
        f.write(goal_aisp)
    with open(f"backlog/{gid}.md", "w") as f:
        f.write(backlog)
    with open(f"library/Unsorry/{mod}.lean", "w") as f:
        f.write(proof)
    with open(f"library/index/{sha}.aisp", "w") as f:
        f.write(index)

    return f"{gid}|{name}|{mod}|{sha}"


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 3:
        sys.exit("usage: mkfiles.py <M> <a> <b>")
    M, a, b = (int(x) for x in argv[:3])
    print(write_goal(M, a, b))


if __name__ == "__main__":
    main()
