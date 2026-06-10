# SPEC-003-D: Swarm Contract (`swarm/protocol.aisp`)

Implements: [ADR-003](../ADR-003-AISP-Coordination-Format.md) · Status: Living · Updated: 2026-06-10

`swarm/protocol.aisp` is the coordination contract every agent loads at session start, together with the vendored AISP grammar (`swarm/AI_GUIDE.md`, MIT, attribution: Bradley Ross — see `swarm/README.md` for provenance).

## Contract contents (blocks)

| Block | Encodes |
|---|---|
| `⟦Ω:Foundation⟧` | Design principles as invariants: kernel-only oracle, repo-only infrastructure, machine-validated artifacts, branch protection map |
| `⟦Σ:Records⟧` | The five record types and their path grammars (detailed per-record rules: SPEC-003-A/B/C) |
| `⟦Γ:Claims⟧` | Claim push semantics, first-push-wins, TTL 7200 s, cardinality per phase, release |
| `⟦Γ:Fidelity⟧` | Dual independent translation, normalization, match ⇒ `translated`+sha, mismatch ⇒ `flagged`, 20 % false-positive kill criterion |
| `⟦Γ:Affinity⟧` | +1 merge / −10 fail, viability threshold τ_v = −5, gap-based selection |
| `⟦Λ:Loop⟧` | pull → select → claim → work → verify → check-in; budgets (≤ 40 turns, ≤ 1800 s wall, ≤ 2 attempts) |
| `⟦Χ:Errors⟧` | Error → recovery mapping (malformed ⇒ Gate B reject; expired ⇒ reap; collision ⇒ next goal; budget ⇒ release+exit) |
| `⟦Ε⟧` | Self-declared evidence block |

## Quality bar

- Must validate with the upstream `aisp-validator` (pinned 0.3.0) at **Gold (◊⁺) or better** — design-doc first-milestone requirement and readiness-checklist item (e).
- Measured at authoring time: **◊⁺⁺ Platinum, δ = 1.000, ambiguity 0.010** (validator 0.3.0, mode js).
- Any change to this file is a contract change: it requires an ADR reference in the PR description and re-validation in Gate B's advisory job.

## Constants (single source of truth)

| Constant | Value | Consumers |
|---|---|---|
| `ttl` | 7200 s | claims (SPEC-003-B), reaper (SPEC-004-A), agent.sh |
| reaper interval | ≤ 900 s | SPEC-004-A scheduled workflow |
| translate claim cap | 2 distinct agents | Gate B GB014 |
| prove claim cap | 1 | Gate B GB014 |
| budgets | 40 turns / 1800 s / 2 attempts | agent.sh (SPEC-007-A) |
| τ_v viability | −5 | goal selection |
| fidelity kill criterion | flag FP ≥ 20 % on identical-meaning pairs | Phase-0 trial / ADR-008 if tripped |

Tools must read these values from their own configuration **matching this table**; a mismatch is a bug. (The contract is the normative source; `tools/gate_b/config.py` mirrors it with a test asserting agreement.)

## Acceptance criteria

1. `npx aisp-validator@0.3.0 validate swarm/protocol.aisp` exits 0 at tier ≥ ◊⁺.
2. `tools/gate_b/tests/test_contract_constants.py` asserts the constants table matches `tools/gate_b/config.py`.
3. The contract names every record type that Gate B validates, and no other.
