#!/usr/bin/env python3
"""Materialise the 5-file proof artifact shared by every seedkit family.

Every family — divisibility (`mkfiles`), ZMod residue (`mkfiles_residue`),
telescoping power sums (`mkfiles_telescoping`), geometric/Faulhaber closed forms
(`mkfiles_faulhaber`) — writes the *same* five files for one goal::

    goals/<id>.lean              the statement (with sorry)
    goals/<id>.aisp              goal record (status proved, sha, difficulty)
    backlog/<id>.md              human-readable description
    library/Unsorry/<Mod>.lean   the proof
    library/index/<sha>.aisp     index record (statement sha + provenance)

Only the Lean statement, the proof body, the prose, the difficulty and the AISP
``δ`` confidence differ between families; the record *shapes* are identical.
This module is that single shape (ADR/CLAUDE "DRY"): a family writer builds the
varying strings and calls :func:`write_artifacts`, which derives the content
address, writes the five files atomically-enough for the push step, and returns
the ``"<id>|<name>|<Module>|<sha>"`` line that ``split_push.sh`` consumes.

The provenance ``solver`` id is taken from ``$UNSORRY_SOLVER`` (preferred) or
``$SEEDKIT_SOLVER``; if neither is set the writer raises rather than stamping an
anonymous id (ADR-086 — seedkit attribution conforms to the sourcing paradigm).
The ``agent`` id comes from ``$SEEDKIT_AGENT`` (default ``seedkit``), and the
engine is recorded honestly as ``provider≜lean`` with the real closing tactic as
``model`` (``decide`` for the finite-``ZMod`` families, ``ring`` for the
``induction; ring`` closed forms) — attributable to an authenticated identity and
a true engine, with no post-hoc relabel needed.
"""
from __future__ import annotations

import datetime
import os

import tools.lean_sig as LS

# MATHEMATICAL DOUBLE-STRUCK CAPITAL D, matching the existing AISP corpus.
_HDR = "\U0001D538" + "5"


def write_artifacts(
    *,
    gid: str,
    name: str,
    goal_lean: str,
    proof: str,
    summary: str,
    source: str,
    reference: str,
    difficulty: int,
    delta: str,
    model: str,
    provider: str = "lean",
    solver: str | None = None,
    agent: str | None = None,
    date: str | None = None,
) -> str:
    """Write the 5 artifact files for one goal and return
    ``"<id>|<name>|<Module>|<sha>"``.

    ``goal_lean`` is the statement file verbatim (``import``…``sorry``); its
    content address (`tools.lean_sig.statement_sha`) is the index key and is
    embedded in both AISP records. ``difficulty`` must lie in ``0..9`` — Gate B
    rejects anything outside that band (GB003), so an out-of-range value is a
    generator bug and is raised here rather than written out to fail later.
    """
    if not 0 <= difficulty <= 9:
        raise ValueError(
            f"difficulty {difficulty} out of range 0..9 for goal {gid!r} "
            f"(Gate B GB003 would reject it)"
        )

    mod = LS.camel_name(gid)
    solver = solver or os.environ.get("UNSORRY_SOLVER") or os.environ.get("SEEDKIT_SOLVER")
    if not solver:
        raise ValueError(
            "seedkit refuses to stamp anonymous provenance (ADR-086): set "
            "UNSORRY_SOLVER (preferred) or SEEDKIT_SOLVER to the authenticated solver id"
        )
    agent = agent or os.environ.get("SEEDKIT_AGENT", "seedkit")
    date = date or datetime.date.today().isoformat()
    sha = LS.statement_sha(goal_lean)

    goal_aisp = (
        f"{_HDR}.1.goal.{gid}@{date}\n"
        f"γ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{\n"
        f"  id≜{gid}\n"
        f"  phase≜prove\n"
        f"  status≜proved\n"
        f"  difficulty≜{difficulty}\n"
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
        f"⟦Ε⟧⟨δ≜{delta};τ≜◊⁺⟩\n"
    )

    backlog = (
        f"# {gid}\n\n"
        f"{summary}\n\n"
        f"- **Source:** {source}\n"
        f"- **Reference:** {reference}\n"
        f"- **Difficulty:** {difficulty}\n"
    )

    index = (
        f"{_HDR}.1.lemma.{sha[:12]}@{date}\n"
        f"γ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{gid}; name≜{name}}}\n"
        f"⟦Σ:Source⟧{{src≜goals/{gid}.lean}}\n"
        f"⟦Γ:Tags⟧{{tags≜⟨⟩}}\n"
        f"⟦Λ:Meta⟧{{use≜0; aff≜0}}\n"
        f"⟦Π:Provenance⟧{{solver≜{solver}; agent≜{agent}; "
        f"provider≜{provider}; model≜{model}; attempts≜1}}\n"
        f"⟦Ε⟧⟨δ≜{delta};τ≜◊⁺⟩\n"
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
