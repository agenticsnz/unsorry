"""Gate B constants — a mirror of the swarm contract (SPEC-003-D).

The normative source is ``swarm/protocol.aisp`` (plus SPEC-003-A for the
prose-density ceiling). ``tests/test_contract_constants.py`` asserts that this
mirror agrees with the contract; a mismatch is a bug here, never grounds to
edit the contract.
"""
from __future__ import annotations

# ⟦Γ:Claims⟧ — claim TTL and reaper cadence
TTL_SECONDS = 7200
TTL_MIN_SECONDS = 600
TTL_MAX_SECONDS = 86400
REAPER_INTERVAL_SECONDS = 900

# ⟦Γ:Claims⟧ — live-claim cardinality per goal, by phase
TRANSLATE_CLAIM_CAP = 2
PROVE_CLAIM_CAP = 1

# ⟦Γ:Affinity⟧ — viability threshold and update deltas
TAU_V = -5
AFFINITY_MERGE = 1  # +1 on a proven goal (⊕)
AFFINITY_FAIL = -10  # -10 on a failed prove attempt (⊖); asymmetric, favours proven approaches

# ⟦Σ:Records⟧ Decomp / ADR-009 — decomposition fan-out and depth guards
MAX_DECOMP_SUBS = 8  # SPEC-003-C: at most 8 sub-lemmas per decomposition
MAX_DECOMP_DEPTH = 3  # ADR-009: at most 3 levels of decomposition

# ⟦Λ:Loop⟧ — per-session budgets
BUDGET_TURNS = 40
BUDGET_WALL_SECONDS = 1800
BUDGET_ATTEMPTS = 2

# SPEC-003-A GB009 — quoted-prose density ceiling in formal blocks
PROSE_DENSITY_CEILING = 0.30

# ADR-024 cross-cycle lesson memory — max characters of a failure signature in
# a proof-run ⟦Δ:Lesson⟧ block, and the max prior signatures surfaced into a
# prove prompt.
LESSON_SIG_MAX = 280
LESSON_PROMPT_CAP = 3
