# ADR-011: Statement-Binding Gate

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-011 |
| **Initiative** | unsorry Phase 2 — open lemmas and target decomposition |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** Gate A — the soundness boundary that re-verifies every PR against the Lean kernel before it can merge to the verified library (ADR-006) — extended to Phase 2, where the swarm proves chosen *meaningful* targets and decomposes them into sub-lemmas rather than the Int/Nat one-liners of Phase 1,
**facing** the gap the W3 red team exposed and recorded but did not fix (gate-a-redteam-001.md, PR #64): Gate A certifies that a proof is *sound* but never that the merged declaration's *statement* is the one its goal asked for, so a vacuous or weakened restatement under a plausible name passes the build, the axiom audit, leanchecker and the options lint with `axioms: []`,
**we decided for** a **statement-binding check** that runs when a prove goal is marked proved: a Lean meta-check (extending the `axiom_audit` executable or a sibling `lean_exe`) verifies that the merged library declaration's *elaborated* type is definitionally equal to the goal statement's elaborated type, with the goal's normalized-signature content-address sha as a fast pre-filter — making "proved" mean "proved **this** statement", and applying the same binding to every generated sub-lemma and to the final target so a proved target genuinely follows from its goal,
**and neglected** trusting the declaration name (the exact #64 vector), human review of every statement, requiring byte-identical statement text, and deferring the check past Phase 2,
**to achieve** the Lean-side closure of the design doc's "one genuine soundness gap" — binding formal-statement→proof faithfulness to sit alongside the already-built dual-translation gate that binds English→formal faithfulness,
**accepting that** definitional-equality checking has edge cases (universe and implicit-argument differences) that need deliberate care, and that this gate binds the proof to the goal's *chosen* formalisation only — a wrong formalisation still yields a meaningful-looking proof of the wrong thing, which is the fidelity gate's residue, not this gate's, and is stated as such.

## Context

Gate A's soundness argument is fully demonstrated: the W3 red team opened nine real attack PRs and Gate A blocked all nine, the axiom audit proving load-bearing for the `native_decide` and injected-axiom vectors that the `--wfail` build is blind to (gate-a-redteam-001.md). One attacker, PR #64, survived the first pass. It enabled `autoImplicit` (the option split across two lines to defeat the old per-line diff grep) so that `theorem prop_contradiction_elim (h : p) (hn : ¬ p) : ¬ g` auto-bound `p, g` as implicit `Prop`s, and the kernel verified the *vacuous* `∀ {p g : Prop}, p → ¬p → ¬g` under a name claiming it eliminates contradictions. The `autoImplicit` re-enable was patched (PR #65, `check_library_options.py`) and #64 re-run failed — 9/9 blocked. But that fix closed one *vector*, not the underlying *class*. As the red-team file records (lines 55-63): no Gate A layer binds a library theorem's statement to its claimed canonical goal; a vacuously-true or mis-stated theorem under a plausible name still passes, and the proper fix is a statement-vs-canonical binding check. That deeper observation was recorded, not fixed; the index entry's `goal`/`sha` linkage remains advisory and a theorem's *meaning* still relies on review while its *soundness* is fully gated.

This was tolerable for Phase 1. The Phase-1 prove cycle (SPEC-007-A) targets known-true trivia — `int_neg_neg_thm`, `int_add_neg`, `and_comm_imp` — that delegate to a mathlib lemma in a one-line body; phase1-run-001.md records merge rate 0.6 across three merged proofs, with the misses attributable to build-cache friction, not bad mathematics or vacuity. When the target is `−(−n) = n`, a reviewer can see at a glance that the statement is the intended one, and a vacuous restatement would be obvious. The index's content-address sha (SPEC-007-A index-sha rule: `sha256` of the normalized Lean statement string, theorem name and signature included) keys the proved marker but is compared to nothing — the prove cycle writes the index entry from the *same* declaration it proved (step 7), so the sha self-confirms rather than binds.

Phase 2 removes that tolerance by design. The whole value of a Phase-2 target is that its statement *means something*: the recommended first target (Nicomachus, `Σk³ = (Σk)²`) and the follow-on combinatorial-identity and PutnamBench contributions are chosen precisely because they are real, absent-from-mathlib results — and decomposition multiplies the exposure. Decomposition (the sibling Phase-2 decision; SPEC-003-C decomposition records, `Post(A) ⊆ Pre(B)` edges) generates *new* sub-statements, each a fresh place for a sub-lemma to be vacuous or over-general while the parent's kernel proof still type-checks against it. The load-bearing soundness rule of decomposition — a parent counts as proved only when an agent writes a module that imports the subs and proves the parent's exact signature and that module passes Gate A — depends on "proves the parent's *exact* signature" being *checked*, which is exactly what no current Gate A layer does. Without statement binding, decomposition does not just inherit the #64 gap; it manufactures new instances of it at every sub-lemma. The binding check is therefore a prerequisite of trustworthy Phase-2 decomposition, not a follow-up to it.

The gate's authoritative checks already operate on the *elaborated* environment, not on source text — that is why ADR-006 chose the axiom audit (`Lean.collectAxioms` over the compiled environment) over textual pattern matching, and why source-level renaming, whitespace and notation tricks cannot evade it. Statement binding belongs in the same layer and on the same elaborated terms. The mechanism is a meta-check that elaborates both the goal statement's type (from `goals/<id>.lean`'s `theorem` signature) and the merged declaration's type and tests them for definitional equality (`isDefEq` over the kernel-elaborated types), with the goal's already-computed normalized-signature sha as a cheap belt that rejects the obvious mismatch before paying for elaboration. Working on elaborated terms is what makes the check robust: a `sorry`-free proof of a *renamed* or *notation-obfuscated* restatement still presents an elaborated type that defeq must reconcile with the goal's, and a vacuous `autoImplicit`-bound restatement presents a *different* (over-general) elaborated type that defeq rejects.

This gate composes with, and does not replace, the dual-translation fidelity gate already built in Phase 1 (design doc §5; protocol.aisp `⟦Γ:Fidelity⟧`; SPEC-003-C translation records). That gate binds English→formal: two independent agents translate a backlog statement, the normalized forms are diffed, and a match fixes the goal's canonical statement and sha. ADR-011 binds formal-statement→proof: the merged proof must prove the goal's chosen formal statement. The two are orthogonal halves of the design doc's "one genuine soundness gap": fidelity owns "did we formalise the right English?", binding owns "did we prove the formal statement we committed to?". Neither subsumes the other, and an honest account of the residue is that a *wrong* formalisation that both translators happen to agree on would pass fidelity, be bound faithfully by ADR-011, and yield a meaningful-looking proof of the wrong thing — that residue is the fidelity gate's domain (and its measured false-positive budget), explicitly not this gate's.

## Options Considered

### Option 1: Elaborated-type defeq binding check, sha as belt (Selected)
A Lean meta-check (extending `axiom_audit` or a sibling `lean_exe`) elaborates the goal statement's type and the merged declaration's type and asserts `isDefEq`; the goal's normalized-signature content-address sha is a fast pre-filter. Applied to every sub-lemma and to the final target.

Pros: operates on elaborated terms in the same compiled environment as the authoritative axiom audit, so source-level renaming, whitespace and notation tricks cannot evade it — the same robustness argument that vindicated ADR-006's choice of `collectAxioms` over grep; definitional equality is the *correct* equivalence for "same statement", admitting legitimate notation and elaboration differences that a textual compare would falsely reject; the sha belt makes the common case (obvious mismatch) cheap and reuses an artifact the index already computes; one rule covers Phase-2 targets and every generated sub-lemma uniformly, so decomposition does not reopen the #64 class. Cons: defeq has genuine edge cases — universe-level and implicit/instance-argument differences — that need deliberate care so the check neither false-rejects a legitimate proof nor false-accepts a subtly different statement; the check binds the proof to the goal's chosen formalisation only, leaving the wrong-formalisation residue to the fidelity gate; it adds one CI step and one `lean_exe` to keep in lockstep with the Gate A workflow.

### Option 2: Trust the declaration name / status quo (Rejected)
Leave `goal`/`sha` linkage advisory, as today. This *is* the #64 vector: a vacuous or weakened restatement under the right name merges with `axioms: []`. The `autoImplicit` class remains open without a binding check — patching `check_library_options.py` closed one spelling of vacuity, not the ability to merge a theorem whose statement is not the goal's. Unacceptable for Phase-2 targets, whose entire value is that the statement means something, and corrosive under decomposition, which mints new unbound sub-statements.

### Option 3: Human review of every statement (Rejected)
Have a maintainer read every merged statement against its goal. Defeats the autonomy the design is built on, does not scale to a swarm fanning out across a target's sub-lemmas, and is a strictly *worse* checker than definitional equality — a human eyeballing `∀ {p g : Prop}, p → ¬p → ¬g` for "does this eliminate contradictions?" is exactly the failure #64 demonstrated. Reserve human attention for flagged fidelity mismatches (design doc §5), not for a check the kernel can do exactly.

### Option 4: Require byte-identical statement text (Rejected)
Compare the merged declaration's source signature to the goal's character-for-character. Too brittle: legitimate notation, `import`-driven elaboration, and whitespace differences between the goal stub and the proved module would false-positive constantly, and the comparison still operates on source, inheriting the macro/renaming bypass surface ADR-006 rejected. Definitional equality over elaborated terms is the right equivalence; textual identity is both too strict (rejects valid proofs) and not robust (source-level).

### Option 5: Defer past Phase 2 (Rejected)
Keep statement meaning on review, as for Phase 1. Acceptable when targets are `−(−n) = n` trivia a reviewer can verify at a glance; unacceptable the moment the swarm's output is a non-trivial, mathlib-absent target or a generated sub-lemma a reviewer cannot trivially check, and self-defeating given that decomposition (the sibling Phase-2 decision) actively manufactures new unbound sub-statements. Deferral would ship Phase 2 with its headline value — meaningful targets — ungated for meaning.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-006 | Gate A Soundness Enforcement | The binding check is a new authoritative Gate A layer on the elaborated environment, alongside the axiom audit, leanchecker and options lint |
| Refines | SPEC-006-A | Axiom Audit Executable | The defeq check extends the `axiom_audit` executable (or lands as a sibling `lean_exe` in the same workflow), reusing its `importModules`/compiled-environment access |
| Refines | SPEC-006-B | Gate A Workflow | Adds the statement-binding step to `gate-a.yml` and makes it part of the required `gate-a` context |
| Relates To | ADR-009 | Target Decomposition (Phase 2) | Sibling Phase-2 decision; binding applies to every generated sub-lemma and to the final target, so a decomposed target genuinely follows from its goal statement |
| Relates To | ADR-005 | Autonomous Merge Policy | Gate A is the required check the auto-merge policy leans on; binding tightens what "proved" admits |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Gate A Red Team — Round 001 (statement-binding gap, PR #64) | Metrics / evidence | ../metrics/gate-a-redteam-001.md |
| REF-2 | ADR-006 — Gate A Soundness Enforcement | ADR | ADR-006-Gate-A-Soundness-Enforcement.md |
| REF-3 | SPEC-006-A — Axiom Audit Executable | Specification | specs/SPEC-006-A-Axiom-Audit-Executable.md |
| REF-4 | SPEC-006-B — Gate A Workflow | Specification | specs/SPEC-006-B-Gate-A-Workflow.md |
| REF-5 | SPEC-007-A — Agent Loop Script (prove cycle, index-sha rule) | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |
| REF-6 | SPEC-003-C — Translation and Decomposition Records | Specification | specs/SPEC-003-C-Translation-and-Decomposition-Records.md |
| REF-7 | Design doc §5 Statement-fidelity gate, §6 Compounding, §7 Library index, §Soundness | Design document | ../proposals/distributed-research-swarm-plan.md |
| REF-8 | swarm/protocol.aisp — `⟦Γ:Fidelity⟧`, `⟦Σ:Records⟧`, `⟦Γ:Affinity⟧` | Swarm contract | ../../swarm/protocol.aisp |
| REF-9 | phase1-run-001 — Phase-1 prove-cycle metrics (merge rate 0.6) | Metrics | ../metrics/phase1-run-001.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-10 |
| Accepted | unsorry maintainers | 2026-06-10 |
