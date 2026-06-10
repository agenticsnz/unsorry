# ADR-010: Affinity-Weighted, Gap-Based Goal Selection

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-010 |
| **Initiative** | unsorry Phase 2 — open lemmas and target decomposition |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** Phase 2, where the swarm must drive verified proofs toward a chosen unformalised target through a growing tree of decomposed sub-lemmas rather than chew through a flat Phase-1 backlog of ~20 independent one-liners,
**facing** the fact that the loop as built (SPEC-007-A) selects the first claimable goal in lexicographic id order — a deterministic but blind order that ignores both which tactic and decomposition families actually merge and how far a goal sits from importable, already-proved lemmas, so the swarm would re-attempt patterns that have already failed and pick goals it cannot yet reach,
**we decided for** affinity-weighted, gap-based selection as specified in design doc Components §6 and protocol `⟦Γ:Affinity⟧`: rank claimable goals by `(affinity desc, gap asc)` with a lexicographic id tie-break for reproducible trials, where affinity earns `+1` on a merge and `−10` on a failed attempt and a pattern below the viability threshold `τ_v = −5` is skipped and its goal re-queued for re-decomposition, and gap is the count of a goal's unproved dependencies (its distance to the merged library); affinity and usage live on the existing `library/index/<sha>.aisp` entries (which already carry `aff` and `use` fields) and/or a numeric field on goal records, updated by the same gated PRs that merge proofs, so the score is eventually-consistent and strictly advisory,
**and neglected** pure gap-based selection, pure affinity selection, a central scoring service or database, and keeping the lexicographic Phase-1 order,
**to achieve** a self-sharpening work queue that concentrates agent budget on proven approaches that are within reach of the merged library and steers the swarm toward the target instead of scattering it,
**accepting that** affinity is a heuristic and not a guarantee — it can settle into a local optimum (mitigated with an affinity floor and occasional exploration), concurrent affinity updates race (acceptable because the score is advisory and eventually-consistent — never trust-bearing for correctness), and trial determinism depends on the lexicographic tie-break.

## Context

The design doc's compounding mechanism (Components §6) and the protocol's `⟦Γ:Affinity⟧` block both specify a self-sharpening queue: a merge adds `+1` affinity to the goal pattern and decomposition that produced it, a failed attempt subtracts `10`, patterns below a viability threshold are skipped and re-queued for re-decomposition, and agents prefer goals whose gap to the merged library is smallest. The asymmetry (`+1` vs `−10`) deliberately favours approaches that have already been proven to work. None of this is wired today. SPEC-007-A's selection step is explicit that Phase 0 and Phase 1 have no affinity data and that the loop therefore takes the first claimable goal in lexicographic id order — a choice it justifies only as a reproducible default for trials under deliberate collision pressure, not as a strategy for reaching a target.

That default was adequate for the Phase-1 reality. phase1-run-001 ran against a flat backlog of independent `Int`/`Nat` one-liners delegating to mathlib; every goal had a gap of zero (no unproved dependencies) and there was no decomposition tree to navigate, so any selection order reached the same merges. The run landed a merge rate of 0.6, and its dominant throughput problem was not selection quality but fan-out: because claim markers do not persist to `main`, a goal stays claimable until its prove PR actually merges, so under pending auto-merge multiple agents re-selected the same highest-priority unproved goal and produced redundant duplicate PRs (#71 dup of #70, #73 dup of #72). That dup-PR pressure is a property the Phase-2 selection order inherits and, if anything, worsens once decomposition floods the queue with siblings.

Phase 2 changes the shape of the queue. The swarm is pointed at a curated, genuinely unformalised target (the recommended first target is the Nicomachus identity `Σk³ = (Σk)²`, which needs two or three sub-lemmas over an existing mathlib `Σk` lemma and so exercises decomposition records and gap selection without re-opening the statement-binding gap) and drives toward it by decomposition. ADR-009 produces the sub-goals — a decomposition record plus typed `Post(A) ⊆ Pre(B)` dependency edges (SPEC-003-C) — and this ADR decides the order in which the resulting tree of claimable goals is worked. With a real dependency tree, gaps are no longer uniformly zero and patterns genuinely differ in their track record, so lexicographic order stops being free: it would send agents at goals whose dependencies are not yet proved and would re-burn budget on decomposition families that have already failed.

Two boundaries from the design principles constrain the mechanism. First, the repository is the only infrastructure: there is no scoring server, queue server, or central judge, and a second source of truth that could drift from the repo is disallowed. Second, and decisively, nothing outside the kernel is load-bearing for correctness — the index's usage and affinity metadata are advisory, content addressing protects only the integrity of the fetched artifact, and Gate B can never admit anything to the library. Affinity therefore sits firmly on the advisory side of that line: a stale, raced, or even maliciously-wrong affinity score can only misroute effort, never admit a bad proof. This is the property that makes eventual consistency an acceptable cost rather than a soundness hazard.

## Options Considered

### Option 1: Affinity-weighted, gap-based selection, scores on repo artifacts (Selected)

Rank claimable goals by `(affinity desc, gap asc)`, lexicographic id tie-break. Affinity `+1` on merge, `−10` on failed attempt; below `τ_v = −5` a pattern is skipped and its goal re-queued for re-decomposition. Gap is the count of a goal's unproved dependencies (`gap ≜ |deps(g) ∖ proved|`), so goals nearest to importable lemmas rank first and goals with no nearby lemmas are deprioritised until decomposition brings them into range. Scores live on the existing `library/index/<sha>.aisp` `aff`/`use` fields and/or a numeric field on goal records, and updates ride on the same Gate-A/Gate-B PRs that merge proofs.

Pros: implements design doc §6 and protocol `⟦Γ:Affinity⟧` directly; the two signals are complementary — affinity captures *what works*, gap captures *what is reachable* — so neither failure mode of the pure variants applies; storage reuses fields the index schema already carries, adds no new infrastructure, and keeps a single source of truth in the repo; updates are gated, so a score change rides an already-verified merge and cannot be injected out-of-band; the lexicographic tie-break preserves the reproducible-trial property SPEC-007-A relies on; and because the score is advisory, the race on concurrent updates is benign. Cons: affinity is a heuristic that can get stuck in a local optimum (needs an explicit floor and/or an exploration allowance); eventual consistency means an agent can select on a slightly stale score; and the selection step is now stateful in a way that must be kept deterministic for trials.

### Option 2: Pure gap-based selection (Rejected)

Rank only by distance to the merged library, ignoring track record. Rejected because it is blind to which tactic and decomposition families actually merge: it would repeatedly select a near-library goal whose pattern has already failed, re-burning budget on the same dead approach. It discards exactly the `−10` signal the asymmetry exists to capture.

### Option 3: Pure affinity selection (Rejected)

Rank only by pattern track record, ignoring reachability. Rejected because the swarm would chase proven patterns into goals whose dependencies are not yet proved — a high-affinity goal with a large gap is not yet workable, and selecting it wastes a claim and an attempt before the sub-lemmas it needs exist. Pure affinity also accelerates the local-optimum risk by doubling down on whatever has worked so far.

### Option 4: Central scoring service / database (Rejected)

Hold affinity and usage in a separate service or database that agents query at selection time. Rejected because it violates the repository-only-infrastructure principle and introduces a second source of truth that can drift from the merged library — the precise drift hazard the design's anti-drift discipline exists to prevent. It also adds an availability dependency to the selection step for no soundness gain, since the scores are advisory regardless of where they live.

### Option 5: Keep lexicographic order (Rejected)

Retain SPEC-007-A's first-in-id-order selection. Rejected because it is fit for a flat ~20-goal Phase-1 backlog with uniform zero gaps but useless for driving toward a target through a growing sub-lemma tree: it cannot distinguish a reachable, proven-pattern goal from an unreachable or already-failed one, and it does nothing to steer the swarm at the target. Phase 2 is exactly the regime where the order starts to matter.

## Dependencies

| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-007 | Agent Identity and Budgets | Selection runs inside the agent loop and budgets this ADR's `−10`-then-skip behaviour governs; the loop the score steers is the one ADR-007 bounds |
| Relates To | ADR-009 | Decomposition Records and Sub-Goal Generation | Decomposition produces the sub-goals and `Post(A) ⊆ Pre(B)` dependency edges whose unproved count this ADR ranks by; the re-queue-on-skip path feeds back into re-decomposition |
| Refines | SPEC-007-A | Agent Loop Script | Replaces the lexicographic selection step with the affinity/gap ranking; the lexicographic order is retained only as the tie-break |

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Design doc §Components 6 (compounding mechanism), §Components 7 (library index) | Design document | ../proposals/distributed-research-swarm-plan.md |
| REF-2 | swarm/protocol.aisp ⟦Γ:Affinity⟧ — `+1/−10`, `τ_v`, `select`/`gap` | Contract | ../../swarm/protocol.aisp |
| REF-3 | SPEC-003-A — Goal Record Schema (`deps` edges, status, sha) | Specification | specs/SPEC-003-A-Goal-Record-Schema.md |
| REF-4 | SPEC-003-C — Translation and Decomposition Records (`Index` `aff`/`use`, edges) | Specification | specs/SPEC-003-C-Translation-and-Decomposition-Records.md |
| REF-5 | SPEC-007-A — Agent Loop Script (lexicographic selection as built) | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |
| REF-6 | phase1-run-001 — first prove-cycle trial (merge rate 0.6, dup-PR fan-out) | Metrics | ../metrics/phase1-run-001.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-10 |
| Accepted | unsorry maintainers | 2026-06-10 |