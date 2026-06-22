# ADR-078: Sponsor-Registered Targets and Obligation-Discharge Credit

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-078 |
| **Initiative** | Aim the board at the swarm plan's Phase 2: credit progress on real, sponsor-registered proof targets, not standalone atoms |
| **Proposed By** | Ocean (@ohdearquant), drafted by Leo |
| **Date** | 2026-06-20 |
| **Status** | Proposed |

## Context

The swarm plan recommends formal mathematics because it compounds, and names Phase 2 as the destination: point the swarm at "a chosen unformalised result" and drive toward it by decomposition. The decomposition graph is already a first-class object (ADR-009 records sub-lemma statements plus typed dependency edges), the queue already self-sharpens on its own decompositions via affinity (ADR-010, plan §6), and every merged lemma is content-addressed by its statement hash (plan §7).

Non-triviality, by contrast, is enforced one atom at a time. ADR-035's probe elaborates a goal's closed statement under `import Mathlib` and rejects it if a fixed battery (`rfl | trivial | decide | norm_num | omega | simp | simp_all | aesop | ring | linarith | tauto`) closes it. Running it under the full library so `simp`/`aesop` surface renamed duplicates is the part most schemes get wrong and this one got right. But ADR-035 itself records the boundary: the probe is advisory at merge time (the CI backstop is changed-goals-only and non-blocking), it deliberately excludes `nlinarith | positivity | field_simp | gcongr` so real inequalities survive as atomic goals, and a one-shot tactic close is "a heuristic for triviality with genuine false positives."

That leaves a gap, and I will be concrete about it because the fix follows from the diagnosis. Ocean's own runs farmed the current system three ways: the probe is advisory, so a goal sourced outside the pipeline merges unprobed; atomic goals can be restated into many semantically-distinct merges; and any fixed battery has a farmable complement. None of these is closed by a smarter battery or a per-goal hardness oracle (estimating the difficulty of an arbitrary closed statement is about as hard as proving it). The leverage is in what the board treats as a unit of credit.

A natural-but-wrong fix is to let contributors submit a *package* (a root theorem plus its own decomposition skeleton) and score each discharged obligation by its depth and fan-in in that DAG. We reject it (see "neglected" below): when the contributor authors the skeleton, the contributor controls depth and fan-in, so a real-looking root with a long chain of trivial or renamed sub-lemmas farms position directly, and the advisory atomic probe does not stop the padding. That scheme is plausibly *easier* to farm than atoms, not harder. The structure has to be authored by someone who is not the one earning the credit, and the obligations that bear credit have to be non-trivial by construction.

## WH(Y) Decision Statement

**In the context of** a swarm whose stated Phase 2 is the decomposition of target theorems, which already records decomposition DAGs (ADR-009), content-addresses lemmas by statement hash (plan §7), has a working human-sponsor channel for upstreaming (ADR-020), CODEOWNERS-gates its trust surfaces (ADR-019), and zeroes self-dealing credit (the v1.28 self-dispatch rule),

**facing** the fact that atomic credit is farmable (advisory probe, restatement, battery complement) and that simply moving to contributor-submitted package skeletons makes it worse, because the submitter then controls the graph the score reads,

**we decided for** crediting the **discharge of a credited obligation in a sponsor-registered target whose skeleton the discharging contributor did not author**. A *target* is a root statement plus a fixed skeleton of obligations (sub-lemmas carrying `sorry`) and ADR-009 dependency edges, registered through the ADR-020 sponsor channel and reviewed by a code owner because it sits on the scoring trust surface (ADR-019). A *credited obligation* is one that survives a **registration-time probe running the full battery** — ADR-035's set together with the `nlinarith`/`positivity`/`field_simp`/`gcongr` tactics it excludes at sourcing — so that one-tactic-closable nodes are permitted in a skeleton as glue but earn zero. Board credit is **credited-obligations discharged, plus targets completed** — the same shape as today's credited-proof count, restricted to registered-target credited obligations and deduped by statement hash (§7). A discharged obligation's depth and fan-in are recorded as **advisory** ordering signals only, never as the score,

**and neglected** (a) contributor-submitted package skeletons scored by depth/fan-in — the submitter controls the graph, so depth, fan-in, and longest-path are all directly farmable and the advisory atomic probe does not stop trivial padding; (b) a larger or smarter tactic battery at sourcing — the complement stays farmable; (c) a per-goal hardness oracle — difficulty estimation is as hard as the proof; (d) making depth/fan-in itself the score — it is not a reliable proxy for difficulty (deep-but-trivial chains exist; shallow-but-hard lemmas are common) and every normalization of "depth on a DAG with diamonds and shared sub-dependencies" is its own attack surface; (e) the `difficulty` 0–5 self-tag (SPEC-003-A), an honor rule automation routes around; (f) trusting a registered skeleton without a non-triviality probe on its obligations — that reopens the farm on the sponsor side,

**to achieve** a board that measures progress toward completing real, sponsored proof targets — the plan's Phase 2 made into the scored unit — on machinery the project already has (sponsor channel, code-owner review, decomposition edges, statement-hash dedup, self-dealing-zero, the ADR-035 probe),

**accepting that** non-triviality enforcement moves to **registration time and becomes blocking there** for credit: a node earns credit only if the full-battery probe cannot close it, and registration is code-owner-reviewed. This is affordable precisely because targets are rare and sponsor-paced, unlike per-merge gating. The irreducible residue is sponsor-plus-owner collusion, addressed and bounded below.

## Why this is not farmable, and why it is worth more

Hardness is not a property of a goal in isolation; it is a property of where the goal sits in a structure someone built on purpose. The defense "you cannot manufacture the sub-lemmas of a theorem you did not architect" only holds when the architect is not the farmer. This ADR puts the architect on the sponsor side, and puts a non-triviality floor on every credited node:

- **A contributor controls nothing the score reads.** The skeleton is fixed at registration; a contributor cannot add depth, widen fan-in, or split an obligation. Self-registered targets earn the registrant zero (the existing self-dealing rule). So the contributor-side farm is gone.
- **A sponsor cannot manufacture value-free credit either.** Every credited obligation must survive the full battery, including the `nlinarith`/`positivity`/`field_simp`/`gcongr` tactics excluded at sourcing, so a skeleton padded with easy lemmas yields zero credited nodes — and a target with no credited obligation at all earns nothing, neither per-obligation credit nor a completion bonus, because the completion bonus is pro-rata over a target's credited obligations and an all-glue target's recipient set is empty. Registration is code-owner-reviewed (ADR-019). The remaining attack — a sponsor and a code owner colluding to register a genuinely-non-trivial-but-strategically-chosen target and farm it through confederates — requires corrupting two trusted roles, produces real proofs of real non-trivial obligations toward a real target (value, not noise), and leaves an auditable provenance trail (ADR-023, and the phantom-attribution guard ADR-037). That is the same trust floor the entire sponsored-upstreaming model already stands on.
- **Valuable.** Discharging these obligations advances a real, sponsored proof toward completion — the "enabling public good" the plan names — instead of accumulating disconnected atoms.

This is also the substrate for the thread's direction #2, crowd-sourcing large `sorry`-skeletons. Untrusted distributed contributors, Gate A re-verifying from scratch in the kernel (ADR-048), statement-hash dedup (§7), provenance (ADR-023): aimed at registered targets, that machine crowd-sources the discharge of a large skeleton. The engine is right; it was aimed at atoms and can be aimed at targets.

To be clear about layering (so this is not confused with §6): ADR-010/§6 affinity governs the swarm's *internal* selection over its own failed-goal decompositions and is unchanged. This ADR governs *board credit*, and reads only the sponsor-registered target structure. The two do not interact.

## Consequences

- **Positive.** Credit requires occupying a real, non-trivial position in a structure the earner did not author, which removes the farming incentive at its root rather than fighting it tactic by tactic. The board becomes a readout of Phase-2 progress. The mechanism reuses the sponsor channel (ADR-020), code-owner review (ADR-019), decomposition edges (ADR-009), statement-hash addressing (§7), the self-dealing-zero rule, and the ADR-035 probe already in the tree. It composes with, rather than replaces, ADR-035, which still guards free-standing atomic sourcing.
- **Cost.** It needs a target registry (root + fixed skeleton + edges), a registration-time full-battery probe, and a scoring pass in the leaderboard tool — all CODEOWNERS-gated trust surfaces (ADR-019) shipping human-reviewed. During transition the board runs dual-track (atom credit and registered-target credit) with a deliberate sunset.
- **Residue (stated plainly).** The full-battery floor is still a tactic-close heuristic, so the line between "credited" and "glue" has false positives at the `nlinarith`/`positivity` boundary; the consequence is conservative (a borderline-easy node earns nothing), which is the safe direction. Sponsor-plus-owner collusion is the irreducible floor described above. Registration consumes finite code-owner bandwidth; it inherits the bandwidth assumptions of ADR-020 and adds no new unbounded review surface, since unregistered submissions simply do not score. Depth/fan-in being advisory means the board does not claim to rank mathematical difficulty, only contribution to completing registered targets — the honest claim.

## A first target

Ocean is ready to register the first one. He will open-source the full Lion proof, several times the size of the LNkernel sample linked earlier in the thread, as the first sponsor-registered Phase-2 target, and help bring in mathematicians who have their own skeletons to register. The natural next artifact is the SPEC that accompanies this ADR (the target-registry format, the registration-time full-battery probe, and the credit function), with a small worked example scored both ways so the difference is concrete before any board change ships.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Distributed Autonomous Research Swarm plan (Phase 2, §6, §7) | Proposal | docs/proposals/distributed-research-swarm-plan.md |
| REF-2 | Goal Decomposition on Prove-Budget Exhaustion | Decision | ADR-009-Goal-Decomposition.md |
| REF-3 | Affinity-Weighted, Gap-Based Goal Selection | Decision | ADR-010-Affinity-Gap-Selection.md |
| REF-4 | Human-Sponsored Upstreaming (the registration channel reused) | Decision | ADR-020-Human-Sponsored-Upstreaming.md |
| REF-5 | CI Supply-Chain & Workflow Protection (CODEOWNERS trust surfaces) | Decision | ADR-019-CI-Supply-Chain-Protection.md |
| REF-6 | Optional Proof Provenance and Leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-7 | Non-Trivial Theorem Enforcement (the probe this complements and reuses at registration) | Decision | ADR-035-Non-Trivial-Theorem-Enforcement.md |
| REF-8 | Corroborated Solver Provenance — phantom-attribution guard | Decision | ADR-037-Corroborated-Solver-Provenance.md |
| REF-9 | Discussion: triviality, hardness, and what to reward | Discussion | #3217 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | Ocean (@ohdearquant) | 2026-06-20 |
