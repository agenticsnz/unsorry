# ADR-009: Goal Decomposition on Prove-Budget Exhaustion

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-009 |
| **Initiative** | unsorry Phase 2 — open lemmas and target decomposition |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** Phase 2, where the swarm must drive verified proofs toward chosen unformalised targets by splitting goals that no single prove attempt can close — the compounding mechanism the design doc (§6, §Phasing) reserves for this phase but which Phase 1 deliberately deferred (SPEC-007-A prove step 11: a prove failure is just release + flag, "no decomposition"),
**facing** the as-built reality that prove failures currently produce no structural progress (phase1-run-001: merge rate 0.6, the open failures all infrastructure not mathematics, nothing reshapes the queue), that the kernel — not goodwill — is the only soundness oracle (ADR-006), and that any decomposition machinery must not widen the trust boundary,
**we decided for** committing a SPEC-003-C decomposition record on prove-budget exhaustion that splits the parent into sub-lemma goals with typed `Post(A) ⊆ Pre(B)` dependency edges, requeues each sub-lemma as a fresh `open` prove goal (`src` = the decomposition record), and parks the parent at `status≜blocked` until its sub-lemmas are proved, after which the parent becomes claimable again with the sub-lemmas available as library imports,
**and neglected** human decomposition of hard goals, monolithic retry with a larger budget, trusting the dependency edges as the proof structure (skipping the parent's own kernel check), and an external planner service,
**to achieve** a self-sharpening queue that converts a failed monolithic attempt into smaller reachable units and compounds proven sub-lemmas into the library, without moving anything that is load-bearing for correctness off the kernel,
**accepting that** decomposition spends compute on sub-lemmas that may never compose, that it churns the queue, that it relies on the affinity and gap-based selection of ADR-010 to actually converge on the target rather than wander, and that — per the red-team finding — every generated sub-statement is a new place to be vacuous or over-general, so the statement-binding work that gates parents must also gate generated subs.

## Context

The design doc's core claim for formal mathematics is that the work *compounds*: "every proved lemma becomes an importable dependency; hard goals that resist proof are split into sub-lemmas that re-enter the queue" (§Recommendation, §6). Phase 1 built only half of that loop — the prove cycle (SPEC-007-A) claims a goal, drives `claude` to write a library module that re-states the theorem and proves it, self-verifies with `lake build --wfail` plus the axiom audit, and merges through Gate A. On failure it stops: SPEC-007-A prove step 11 is explicit that the decomposition path is Phase 2 and that a Phase-1 prove failure is "just release + flag." phase1-run-001 confirms the loop works for the trivial band (3/5 merged, all soundness-clean) but produces no structural progress when an attempt is exhausted — the one genuinely unclosed goal stayed `open` and untouched. Phase 2 is where the failure path starts doing work.

The records and rules already exist on paper. SPEC-003-C defines the decomposition record (`decompositions/<parent-id>.<agent-id>.aisp`): a `parent`, a list of sub-lemmas each with a fresh `Id` and statement, typed edges in the binding form `Post(A) ⊆ Pre(B)`, a `Requeue` clause setting every sub to `status≜open`, and a cap of "at least one sub, at most 8." The protocol (`⟦Σ:Records⟧`) carries `blocked` as a goal status and the `Decomp` record type; `⟦Γ:Affinity⟧` already specifies the `−10` failure penalty, the viability threshold `τ_v ≜ −5`, the `requeue(decomposition)` action below threshold, and gap-based selection `select ≜ argmax(aff, −gap)`. This ADR decides how the prove cycle *uses* those records on budget exhaustion; ADR-010 decides how affinity and gap selection route the resulting queue (currently selection is purely lexicographic and affinity is not wired).

The non-negotiable constraint is soundness. ADR-006 makes the kernel the only oracle and the axiom audit the authoritative gate; the design doc (§7) and protocol (`⟦Ω:Foundation⟧`) state that the index, its affinity metadata, and dependency edges are "advisory only, never load-bearing for soundness." Decomposition must inherit that property exactly: a sub-lemma proved and merged proves nothing about its parent. The parent counts as proved only when an agent writes its own library module that imports the subs, proves the parent's exact signature, and passes Gate A — identical to the normal prove cycle. A decomposition that does not compose simply means the parent never closes (wasted effort), never an unsound parent. The dependency edges are routing hints for selection, not a trust path.

The red team (gate-a-redteam-001, PR #64) exposed the limitation this ADR must respect: Gate A guarantees soundness but not *meaningfulness* — no layer binds a library theorem's statement to its claimed canonical goal, so a vacuous or mis-stated theorem under a plausible name passes the kernel. Decomposition multiplies that surface: every generated sub-statement is a new, machine-authored place to be vacuous or over-general. The statement-binding / canonical-sha fidelity check (Phase-1 work tracked off the red-team finding) must therefore extend to generated sub-statements as a prerequisite of this decision, not a follow-up. ADR-008 remains the reserved, never-triggered fidelity-fallback slot (the protocol's `fp ≥ 0.20 ⇒ fallback` path); this ADR does not reuse it.

## Options Considered

### Option 1: Agent commits a decomposition record on budget exhaustion; subs requeue, parent blocks then re-proves through the kernel (Selected)
On prove-budget exhaustion the agent commits a SPEC-003-C `decompositions/<parent>.<agent>.aisp` record (the same PR adds the new `goals/<sub>.aisp` records, `src` → the decomposition record), the sub-lemmas enter as fresh `open` prove goals, and the parent moves to `status≜blocked`. When all of a parent's sub-lemmas are proved, the parent becomes claimable again; an agent then proves the parent's own signature with the subs available as imports, and that module merges only via Gate A.

Pros: matches the design doc's compounding mechanism and reuses existing record types and rules (SPEC-003-C, protocol `Decomp`/`blocked`/affinity) rather than inventing new ones; soundness is *unchanged* because the parent's final close is an ordinary Gate-A prove — the kernel stays the only load-bearing check and edges stay advisory; a non-composing decomposition wastes compute but can never produce an unsound parent; the failed attempt now feeds the pool and reshapes the queue toward reachable units instead of dead-ending.

Cons: spends compute on sub-lemmas that may never compose; churns the queue (new goals, a blocked parent, sibling claims); fan-out and circular-dependency risks need explicit guardrails (below); does not on its own drive toward the target — it needs ADR-010's affinity/gap selection or it wanders; and it inherits, and multiplies, the unfixed statement-binding gap, so the canonical-sha fidelity check must cover generated subs before this is safe to run.

Guardrails (part of the selected option): cap decomposition breadth at SPEC-003-C's existing limit of 8 subs and cap depth (e.g. ≤ 3 levels) to prevent runaway fan-out — compounded with the known throughput risk (phase1-run-001: agents re-select the same goal under pending auto-merge, producing duplicate PRs), an uncapped sibling flood would worsen dup-PR churn. Dependency edges must form a DAG: SPEC-003-C defines the `Post(A) ⊆ Pre(B)` edge type but specifies no acyclicity check (a likely gap — verify against Gate B before relying on it), so cycle detection/rejection must be added at Gate B. A sub-lemma must be a strictly smaller goal: a decomposition that re-emits the parent (or an equal goal) is rejected, so depth caps are not the only termination guard.

### Option 2: Human decomposition of hard goals (Rejected)
A maintainer hand-splits goals the swarm cannot close. Rejected: it defeats the autonomy the swarm exists for and reintroduces a human into the per-goal loop the design explicitly keeps humans out of (humans review naming/duplication, never the proof or its structure).

### Option 3: Monolithic retry with a larger budget (Rejected)
On exhaustion, re-claim the same goal with more attempts/wall time. Rejected: it does not compound (a closed monolith yields no importable sub-lemmas) and does not reshape the queue toward what is reachable; phase1-run-001's open failure was infrastructure, not budget, so "more budget" addresses the wrong axis.

### Option 4: Trust the dependency edges as the proof structure / skip the parent's final kernel check (Rejected)
Mark the parent proved once its sub-lemmas are proved and their `Post ⊆ Pre` edges line up, without an agent proving the parent's own signature. Rejected: this is precisely the unsound trust path ADR-006 forbids — it makes the edges (advisory metadata) load-bearing for correctness, and sub-lemmas alone prove nothing about the target. Prior art is unanimous here (native `have`/`suffices`, hammer reconstruction, DeepSeek-Prover-V2's recombination reward, APOLLO's re-verify): subgoals only count when recomposed and re-checked by the kernel.

### Option 5: External planner service (Rejected)
Delegate goal-splitting to a hosted planner/decomposer outside the repo. Rejected: it violates the repo-only-infrastructure principle (`⟦Ω:Foundation⟧`: `infra ≜ git`, `judge ≜ ∅`) and adds a trust/availability dependency that buys nothing the in-repo decomposition record cannot.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-006 | Gate A Soundness Enforcement | The parent still closes only through the kernel; edges/subs are never load-bearing. Decomposition does not relax the gate; the statement-binding fidelity check must extend to generated subs. |
| Depends On | ADR-007 | Agent Identity and Budgets | Decomposition fires on budget exhaustion; sub-lemma proving consumes the same per-agent budgets and identity trail. |
| Relates To | ADR-010 | Affinity-Weighted Gap Selection | Affinity (`−10`/`+1`, `τ_v ≜ −5`, `requeue(decomposition)`) and gap-based selection are what make the requeued subs converge on the target rather than wander. |
| Refines | SPEC-003-C | Translation and Decomposition Records | This ADR puts the already-specified decomposition record into the prove cycle (the slot SPEC-007-A step 11 deferred), and motivates adding an acyclicity/strictly-smaller-goal check absent from the current spec. |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Distributed research swarm plan — §6 Compounding, §7 Library index, §Phasing (Phase 2), §Risks | Design document | ../proposals/distributed-research-swarm-plan.md |
| REF-2 | swarm/protocol.aisp — ⟦Σ:Records⟧ (Decomp, `blocked`), ⟦Γ:Affinity⟧ (`−10`/`+1`, `τ_v`, gap selection, `requeue(decomposition)`) | Swarm contract | ../../swarm/protocol.aisp |
| REF-3 | SPEC-003-C — Decomposition record schema and `Post(A) ⊆ Pre(B)` edges | Specification | specs/SPEC-003-C-Translation-and-Decomposition-Records.md |
| REF-4 | SPEC-007-A — Agent loop as built (prove cycle; step 11 defers decomposition; lexicographic selection, affinity not wired) | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |
| REF-5 | Gate A Red Team — Round 001 (statement-binding / vacuity gap, PR #64) | Metrics / evidence | ../metrics/gate-a-redteam-001.md |
| REF-6 | Phase-1 swarm trial — run 001 (merge rate 0.6, build friction, dup-PR throughput note) | Metrics / evidence | ../metrics/phase1-run-001.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-10 |
| Accepted | unsorry maintainers | 2026-06-10 |
