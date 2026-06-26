# ADR-106: Deprioritise low-difficulty template proofs in the queue dispatcher

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-106 |
| **Initiative** | throughput / dispatch fairness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-26 |
| **Status** | Proposed |

## Context

A live audit (2026-06-26) of the queue dashboard found **389 submissions waiting**, of which
**336 belong to a single solver** (`@ohdearquant`) and are **low-difficulty template proofs**
(`template-ring-cofactor`, `template-zmod-decide`, `ring`, …) — some queued for a week. Meanwhile
the genuinely hard work that moves the needle — the four v2.0.0 benchmark suites (putnam/imo/
minif2f/combibench) — is rare (≈0→6→17/day) and competes for the same governed dispatch slots.

ADR-075 already round-robins the queue **by solver** so one high-volume contributor can't starve
the rest (max-min fairness). But it is **difficulty-blind**: within the fair share, a solver's
trivial template floods dispatch on equal footing with hard proofs. The project's own
`score_policy` weights `difficulty_points ×100` vs `credited_proofs ×25` — raw template volume is
deliberately the *minor* term — so spending scarce dispatch/verify capacity on template floods
ahead of hard proofs is misaligned with what the system values.

The queue board (`docs/queue.json`, ADR-066) already records a `model` per queued branch, which
labels the template generators precisely — so the difficulty signal needed to reorder is already
present at dispatch time.

## Decision

**Add a difficulty tier to the dispatcher's ordering: dispatch high-difficulty branches before
low-difficulty (template) ones, with ADR-075 per-solver round-robin applied WITHIN each tier.**

- A branch is **low difficulty** iff its queue-board `model` matches a known template/trivial-
  tactic marker (`template`, `ring`, `decide`, `sympy`, `norm_num`). A branch with **no model**
  or an unrecognised model is **high** — fail-safe: only KNOWN-trivial work is deprioritised,
  never blindly.
- The dispatcher emits **all high-tier branches (round-robin'd across solvers) before any low-
  tier branch (also round-robin'd)**. Within each tier, ADR-075 fairness is unchanged.
- Logic lives in a unit-tested module (`tools/dispatch/fair_order.py`); `agent.sh::fair_dispatch_
  order` calls it. Reversible: `UNSORRY_DIFFICULTY_DISPATCH=0` → fairness-only (ADR-075);
  `UNSORRY_FAIR_DISPATCH=0` → legacy lexical.

## Consequences

- **Throughput of *valued* work rises.** Hard proofs (benchmarks, decompositions) reach Gate A
  and merge ahead of the template backlog, so realized *difficulty-weighted* throughput — the
  metric the leaderboard scores — improves even though raw count is unchanged. The template flood
  still drains (it dominates volume), just at lower priority when hard work is available.
- **No starvation.** Hard work is scarce (≈17/day vs hundreds of templates), so the low tier still
  receives the bulk of dispatch capacity once the small high tier is served each round; the
  governor cap continues to meter both. Per-solver fairness (ADR-075) is preserved within tiers.
- **Soundness untouched.** This only REORDERS refs — dedup (ADR-064/071), the governor (ADR-058)
  and Gate A still decide what dispatches and what merges. The `model` field is advisory metadata,
  never a trust input.
- **Maintenance.** The low-difficulty marker list must track new template models; it is one
  documented constant with tests, and an unknown model fails safe to high.

## Alternatives considered

- **Tighter per-author cap for template floods.** The admission per-author cap (20) already limits
  open PRs; lowering it for one solver is punitive and brittle. Difficulty-tiering targets the
  *work*, not the *contributor*, and naturally generalises.
- **Difficulty as a tie-break inside each solver's bucket (not a global tier).** Weaker: a solver
  whose entire backlog is templates gains nothing, and hard work from a *late-sorted* solver still
  waits behind another solver's templates. A global tier (high before low) is the clearer lever.
- **Stop sourcing/accepting template proofs.** Out of scope and undesirable — templates are valid,
  difficulty-discounted contributions; the goal is to *order* them, not reject them.

## References

ADR-075 (per-solver round-robin fairness — extended here), ADR-066 (queue board provenance / the
`model` field), ADR-064/071 (dispatch dedup), ADR-058 (governor caps), ADR-005 (autonomous merge).
Leaderboard `score_policy` (difficulty-weighted scoring). Audit tracked on #5678.
