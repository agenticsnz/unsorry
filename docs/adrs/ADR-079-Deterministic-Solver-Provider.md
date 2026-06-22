# ADR-079: Deterministic Solver Provider — Zero-LLM Template/sympy Discharge, Honestly Attributed

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-079 |
| **Initiative** | Fold in deterministic (sympy/template) solving as an optional provider — discussion #3217 direction #1 |
| **Proposed By** | Ocean (@ohdearquant), drafted by Leo |
| **Date** | 2026-06-20 |
| **Status** | Proposed |

## Context

Ocean's runs produced a large set of `template-*` proofs that were **deterministic sympy/Python solves, not LLM solves** — disclosed publicly in #3217 ("not solved by LLM, solved by sympy"). They had been written into provenance as `provider≜claude; model≜template-*`, which the board renders as a model attribution. That record is being corrected to `provider≜python; model≜sympy` (the honest one), and Chris asked, as direction #1 of the thread, to "fold in your method for deterministic solving (optional, non-breaking)." This ADR contributes the method. It is scoped narrowly and on purpose: it adds a solver and an attribution convention, and it does **not** claim to add a new anti-farming guarantee — credit and provenance integrity stay with the ADRs that own them (ADR-035, ADR-078, ADR-023/037).

The method is deterministic and carries no model in the solve loop. It has two tiers:

1. **Tactic pre-pass.** Elaborate the goal and try the ADR-035 triviality battery *as a solver* rather than as a gate: if one tactic (`rfl`/`decide`/`norm_num`/`ring`/`omega`/…) closes it, emit `by <tactic>` and stop. The battery already exists in `tools/sourcing/check_triviality.py`; this reuses it the other way round. Every tier-1 output is **trivial by ADR-035 by construction** — a single battery tactic closed it.
2. **sympy-assisted construction.** For declared elementary families (integer factorisation/divisibility, CRT/`ZMod`, polynomial/`ring` identities, `linear_combination` witnesses), compute the witness or normal form in sympy and emit the corresponding kernel-checkable Lean proof. This reaches a band the bare battery cannot — a specific large factorisation `decide` will not brute-force becomes a one-line proof once sympy hands over the witness. Tier-2 outputs are mechanical template work, but they are **not** all trivial-by-ADR-035: a `linear_combination` with a computed witness, for instance, is not in the ADR-035 set and need not fall to ADR-078's fuller battery either. Where an output is a genuine non-trivial proof, the honest record of *who found it* is "a deterministic procedure", and that is the attribution this ADR standardises.

Whatever the tier, soundness is untouched: a candidate is just a `by …` block, and the existing path re-elaborates it and the kernel re-checks (ADR-006/048). Nothing is trusted on the provider's word, exactly as ADR-013 already requires for every provider.

The reason to want this is cost and coverage. A goal a deterministic procedure closes instantly is a goal no LLM has to attempt, and ADR-013 records that a failed LLM attempt costs a full `UNSORRY_WALL` window plus a Lean build. The elementary families the Identity Engine (ADR-043) targets — ZMod-decide divisibility, SOS inequalities, telescoping identities — are exactly the band a deterministic provider clears for free, freeing model budget for the hard, credited obligations.

On credit, the honest accounting is narrow. This ADR does **not** decide what scores; ADR-035 (the triviality probe), ADR-078 (credited vs glue obligations of sponsor-registered targets), and ADR-023/037 (provenance) already do. A deterministic solve earns whatever those mechanisms grant any proof with the same statement and the same recorded provenance. What this ADR adds is the convention that such a solve is recorded `provider≜python; model≜sympy`, so the board is not told an LLM did it. That convention is the same kind of un-kernel-enforceable, spoofable record ADR-013 already lives with for model identity — a contributor can write a false provider, and defeating that is the job of the provenance subsystem (ADR-023/037), not this ADR. So this ADR neither closes nor widens the provenance-spoofing hole; it states the honest default and points at where spoof-resistance is owned.

One coupling must be named plainly, because it is the real risk. A free, fast proof factory for easy goals is a farming accelerant *if credit attaches to easy or atomic goals*. Under today's advisory atomic model it partly does, so a deterministic factory pointed at the board would be a farm vector. That is precisely why this ADR is proposed as a **companion to ADR-078**: once credit attaches to non-trivial, sponsor-authored obligations and ADR-035 is blocking at registration, the factory can only discharge zero-credit glue and pre-pass work, which is its sanctioned use. The value of the deterministic provider is therefore real only alongside that credit reform; on its own it would need ADR-035 made blocking before it is safe to enable against the board.

## WH(Y) Decision Statement

**In the context of** a provider/model seam where model choice is a performance knob and never a soundness one and provider identity is explicitly not kernel-enforceable (ADR-013), an ADR-035 tactic battery already in the tree, the elementary-identity families the swarm is strongest at (ADR-043), and the companion proposal ADR-078 moving credit onto non-trivial sponsor-authored obligations,

**facing** a large class of goals (template-matchable identities and witness-constructible statements) that an LLM closes only after burning a full wall plus a build, while a deterministic procedure closes them instantly and for free — and our own runs showing deterministic solving works at scale but was mis-attributed to a model,

**we decided for** an **optional, off-by-default deterministic provider** (`provider≜python; model≜sympy`) with the two tiers above, re-verified by Gate A like any proof, recorded with honest python/sympy provenance, and used for a zero-LLM **glue discharger** on ADR-078 targets, a fast **pre-pass** before an LLM is dispatched, and **Phase-1 autoformalisation** coverage,

**and neglected** (a) claiming this ADR itself makes deterministic output non-creditable — it does not; credit is decided by ADR-035/078/023, and asserting a guarantee this layer cannot enforce would be the over-claim we are avoiding; (b) attributing deterministic solves to any LLM provider — the dishonest record we are fixing; (c) sourcing tier-2 output as standalone atoms through ADR-043 — most fail that pipeline's triviality gate, and the rest should not be minted as atoms regardless; (d) enabling it against the board before ADR-035 is blocking or ADR-078 is in force — without one of those a free factory is a farm vector, named above; (e) building cryptographically attested, spoof-proof provenance scoring into this ADR — that is a separate subsystem belonging to ADR-023/037's evolution, out of scope here; (f) making it on-by-default or coupling it to soundness — it is a cost/coverage knob, off unless asked for,

**to achieve** free, instant discharge of the elementary/template band so LLM budget is spent on hard credited obligations, on the existing provider seam, with an honest attribution standard,

**accepting that** coverage is bounded to template-matchable and witness-constructible families (no general reasoning); that the non-credit treatment of its output rides on honest, spoofable provenance (the ADR-013 residue, deferred to ADR-023/037), not on a new gate; that the deterministic factory is only safe against the board alongside ADR-078 or a blocking ADR-035; and that the family→template surface is a governed surface that must be reviewed as it grows.

## Consequences

- **Positive.** A whole band of goals is discharged for zero model cost and zero wall/build waste, freeing LLM budget for hard targets. It establishes `provider≜python; model≜sympy` as the honest record for deterministic solves, replacing the `template-*`/`claude` mis-attribution. It composes with the work already in the tree: a glue discharger for ADR-078, a pre-pass for ADR-013's dispatch, a producer for ADR-043's families and the plan's Phase-1 on-ramp. Soundness is untouched — Gate A re-verifies in the kernel regardless of provider.
- **Cost.** A new provider implementation plus an optional sympy dependency, both off by default and additive. The family→template mappings of tier 2 are a maintained, reviewed surface that grows with the families it covers. Pointing the provider at the board before the credit reform (ADR-078) or a blocking ADR-035 would be unsafe, so the safe rollout is sequenced behind those.
- **Residue (stated plainly).** Honest attribution is enforced by convention plus the provenance record, not by the kernel — a contributor can record a false provider, the same un-closeable residue ADR-013 names, and its resolution is deferred to ADR-023/037, not solved here. There is a relabeling path — generate a proof deterministically off the board, then submit the artifact through a normal `prove(...)` PR as a model's work — but it is **not created or widened by this ADR**: sympy is public and provenance is spoofable today, so the path exists with or without an in-repo deterministic provider. What this ADR adds is the honest in-repo path plus a guard: enabling the provider against the board is gated on **both** the credit reform (ADR-078 / blocking ADR-035) **and** corroborated provenance (ADR-023/037), enforced by the SPEC §1 board-submission guard rather than left to operator discipline. End-to-end corroboration of an artifact's origin is ADR-023/037's surface, not built here. The tier-2 family surface is an abuse vector if it grows unreviewed, which is why §3 of the SPEC puts it under CODEOWNERS with a per-family credit-posture assertion.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Model & Effort Policy (the provider/model seam; provider identity not kernel-enforceable) | Decision | ADR-013-Model-Effort-Policy.md |
| REF-2 | Non-Trivial Theorem Enforcement (the battery reused as a solver) | Decision | ADR-035-Non-Trivial-Theorem-Enforcement.md |
| REF-3 | The Identity Engine (the elementary families this discharges) | Decision | ADR-043-Identity-Engine.md |
| REF-4 | Sponsor-Registered Targets and Obligation-Discharge Credit (glue / non-credit; farm-bounding) | Decision (proposed) | ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md |
| REF-5 | Optional Proof Provenance and Leaderboard (attribution record; spoof-resistance owner) | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-6 | Corroborated Solver Provenance — phantom-attribution guard | Decision | ADR-037-Corroborated-Solver-Provenance.md |
| REF-7 | Distributed Autonomous Research Swarm plan (Phase 1 autoformalisation) | Proposal | docs/proposals/distributed-research-swarm-plan.md |
| REF-8 | Discussion: fold in deterministic solving (direction #1) | Discussion | #3217 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | Ocean (@ohdearquant) | 2026-06-20 |
