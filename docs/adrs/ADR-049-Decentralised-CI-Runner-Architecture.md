# ADR-049: Decentralised CI Runner Architecture — Tiered Split with a Mandatory Cheap Central Re-check

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-049 |
| **Initiative** | unsorry — CI scalability (issue #635) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-15 |
| **Status** | Accepted |

## Context

unsorry's soundness gate (Gate A, ADR-006) is the project's dominant CI cost and its central DoS surface. Per PR it runs a full `lake build UnsorryLibrary --wfail` elaboration (~16–21 min cold, the dominant cost driver; cached by ADR-045), a serialised `axiom_audit` (~6–7 GB/process), a `leanchecker` kernel replay (historically ~20 min/~20 GB, now incremental ~10–30 s via ADR-033), and an ADR-011 statement-binding check. These heavy jobs were already offloaded from free GitHub-hosted runners to **paid namespace.so ephemeral runners** — a centralised stopgap whose cost grows linearly with merged-PR volume and has no asymptote as the autonomous swarm (ADR-005) scales.

[Issue #635](https://github.com/cgbarlow/unsorry/issues/635) asks us to research a *decentralised, secure CI runner architecture* — "SETI@Home but for LLMs proving math" — in which the client runs both the agent and the runner, with stringent checks that the runner's code has not been modified. The investigation, an 8-candidate parallel-agent workflow with adversarial soundness review (full options analysis in [docs/proposals/decentralised-ci-runner-architecture.md](../proposals/decentralised-ci-runner-architecture.md)), produced two load-bearing observations:

1. **The client already runs the runner.** `swarm/agent.sh::prove_local_verify()` already performs `lake build UnsorryLibrary --wfail` + `axiom_audit` + `check_library_options` before opening a PR. The open problem is therefore **trust**, not capability.
2. **Lean splits cleanly at a natural seam.** Expensive *elaboration* (the cost driver, and the part that need not be trusted) is separable from cheap *kernel checking*. A full kernel replay of every swarm proof (~225 s) is already ~4–6× cheaper than one cold elaboration build; an incremental PR replay is ~40–120× cheaper. This makes a mandatory central re-check affordable on **every** PR.

The decision is bounded by the project's standing, non-negotiable invariants: the Lean kernel is the only truth oracle; every contribution must be re-checkable on a **trusted** surface before it lands in the commons; identity is hygiene, never soundness (ADR-007); the CI trust surface is SHA-pinned and CODEOWNERS-gated (ADR-019); mathlib/toolchain are release-pinned for reproducibility (ADR-002). This decision records the recommended *direction* (Status: Accepted). Its substance was already live via ADR-033 (incremental replay/audit) and ADR-045 (olean cache); the implementation contract in [SPEC-049-A](specs/SPEC-049-A-Decentralised-CI-Runner-Architecture.md) is phased. **Phase 0 is delivered** — the §5 conformance regression suite (`tools/gate_a/tests/test_decentralised_runner_conformance.py`, PR #926) that locks in the §2 soundness invariant. **Phase 1** (scoping the central elaboration build to the changed closure) is **closed — not pursued** ([#942](https://github.com/agenticsnz/unsorry/issues/942)): the cost measurement showed the redundant unchanged-module build is already eliminated by ADR-033/045. On a warm-cache CI run the once-per-PR `--wfail` build is ~41 s of a ~8 runner-min/PR gate that is dominated by fixed mathlib-environment loading (axiom audit ~165 s, leanchecker replay ~60 s, three ~25–60 s cache restores — none of which Phase 1 touches), so narrowing the build target buys only low-single-digit % per PR — not worth a soundness-surface change to the TCB control flow. The §5 conformance suite (#926) remains the standing guard. **Phases 2–3** remain future / pilot-gated, each its own decision.

## WH(Y) Decision Statement

**In the context of** unsorry's heavy Gate A verification compute running on paid, centralised namespace.so ephemeral runners whose cost grows linearly and without asymptote as the autonomous swarm scales, with issue #635 proposing to move heavy CI onto contributor machines (which already run the prover via `prove_local_verify()`),

**facing** the inviolable invariant that the Lean kernel is the only truth oracle and every contribution must be re-checkable on a *trusted* surface before it lands — so that the issue's literal "prove the runner code was not modified" requirement, if taken at face value (BYO self-hosted runners, redundant peer consensus, probabilistic spot-audit, or TEE/hardware attestation), would each make runner integrity, a probabilistic vote, an economic penalty, or a silicon vendor's signature load-bearing for mathematical correctness, all defeatable by a contributor with physical access or a throwaway non-cryptographic identity (ADR-007),

**we decided for** a **tiered split**: push the expensive elaboration (`lake build --wfail` + axiom audit) onto the untrusted contributor (which `prove_local_verify()` already runs), and keep a **mandatory, cheap, trusted central re-check** as the *sole* load-bearing soundness gate, run at sampling probability p = 1 on every PR — a re-check that **never trusts a client-supplied `.olean`** but instead re-derives the statement from canonical goal source (ADR-018/ADR-011), re-elaborates the changed-module reverse-import closure from source against dependency oleans that are either rebuilt on trusted CI or restored from a commit-exact trusted-CI cache with provenance, then runs `leanchecker` + `axiom_audit` + statement-binding on that,

**and neglected** BYO self-hosted GitHub Actions runners (a fork PR on a public repo would run the PR head's own gate on contributor-controlled hardware — a forged green Gate A), redundant N-of-M peer consensus (a defeatable vote among non-cryptographic identities; ADR-030 reserves CONSENSUS for domains with *no* cheap verifier, and Lean is VERIFIED), probabilistic spot-audit with reputation (admits a `1 − p` fraction with no trusted re-check, making penalties load-bearing for correctness), TEE/hardware-attested runners (the contributor owns the hardware and has physical access — out of TEE scope; the research surfaced sub-$1000 attestation-key extraction), and the naive "trust client oleans + leanchecker" reading of the split (unsound on crafted-invalid oleans and on real proofs of weakened/renamed statements — the ADR-011 vacuity class),

**to achieve** verification capacity that scales with the swarm while keeping the kernel as the sole oracle on ground the adversary never touches, **dissolving** the "prove the runner was not tampered with" requirement by detecting tampering through *outcome* rather than attestation (a tampered runner can at worst produce something the central kernel rejects),

**accepting that** the headline central-cost reduction is **modest, not SETI-scale** — ADR-033 incremental replay and ADR-045 olean caching already captured most per-PR savings, and the changed-closure re-elaboration is a scoped source build that cannot be safely offloaded without trusting client oleans, so the v1 win is the elimination of the redundant build of *unchanged* modules plus a sub-linear cost slope; that any global-impact change (toolchain/lakefile/gate tooling) forces a full central re-check, so the cost bound is soft and griefable; and that v1 decentralisation is shallow because the irreducible trusted re-elaboration and merge stay central by necessity — that central surface *is* the soundness guarantee.

## Soundness argument (explicit)

1. **Acceptance is decided only by the central re-check.** Nothing lands in `UnsorryLibrary` except by a deterministic verdict produced on a project-controlled surface the adversary never touches. The client's `prove_local_verify()` is advisory, exactly as today.
2. **The central PR-time re-check is the ADR-048 ingest verification.** Once trusted CI verifies an exact proof artifact for a pinned toolchain/mathlib context, later systems may carry that trust forward only through provenance + immutability/byte-identity, never through client attestation.
3. **The central re-check consumes no client artifact as a trusted input.** It (a) re-derives the statement from canonical goal source (ADR-018 create-only goals, ADR-011 binding), (b) re-elaborates the changed-module reverse-import closure from source against dependency oleans that were rebuilt on trusted CI or restored from a commit-exact trusted-CI cache, (c) runs `leanchecker`, (d) runs the serialised `axiom_audit` against the whitelist `{propext, Classical.choice, Quot.sound}`, (e) defeq-binds the proved term to the re-derived statement.
4. **The footgun is named and forbidden.** `leanchecker` replays the environment it is *given* — it trusts olean structure ("prone to crafted invalid `.olean` files") and does not re-derive the statement. So "leanchecker a client-supplied olean" is unsound on (i) crafted-invalid oleans and (ii) real proofs of weaker/renamed statements (the PR-#64 vacuity class). The design closes both by central source re-elaboration and central statement re-derivation; no code path may let a client olean reach `leanchecker` as a trusted input.
5. **Determinism is the precondition.** ADR-002 pinning + Lake lockfile + elan give the ADR-033 byte-identical-rebuild invariant, so the central re-elaboration verifies the same proof the contributor produced. Any trusted-context change forces a full re-check rather than scoping down.
6. **Post-merge full replay is defense-in-depth, not the primary trust boundary.** ADR-048 permits unchanged, already-ingested artifacts to be trusted through provenance and immutability; scheduled or context-triggered full replay remains valuable as a bookkeeping backstop, but ADR-049 does not require every push to `main` to re-derive all soundness from scratch.

Conclusion: soundness is preserved at full strength (C1 = 5) under the threat model "a fully malicious/tampered contributor runner." Identity, reputation, spot-audit sampling, and any peer-consensus signal remain strictly hygiene (ADR-007) — they may throttle abuse or decide how much *expensive elaboration* to re-run, never whether content is admitted.

## Options Considered

### Option 1: Tiered split + mandatory cheap central re-check (Selected)
The recommended hybrid above. **Pros:** the only decentralisation option that keeps soundness at full strength, because acceptance is decided by a mandatory central re-check never by runner integrity/vote/penalty/vendor signature; makes runner tampering detectable by outcome (dissolves the issue's hardest requirement); composes with ADR-002/004/005/019/033/045 at near-zero conceptual friction; v1 is a small CODEOWNERS-reviewable delta on `gate-a.yml`. **Cons:** the cost win is modest (most per-PR savings already captured by ADR-033/045); the cost bound is soft (global-impact PRs force full re-check, which is griefable); v1 decentralisation is shallow (the trusted re-elaboration and merge stay central).

### Option 2: Reproducible-build + content-addressed artifact verification (Rejected as v1; adopted as the Phase-3 engine of Option 1)
Deterministic builds → content-addressed `lean4export` NDJSON, re-checked centrally by a tiny independent checker (e.g. `nanoda`) with no mathlib resident. **Pros:** soundness holds and it captures the fullest cost lever (smallest TCB, removes even the elaborator; enables cross-kernel defense-in-depth). **Cons:** it does not address runner-*code* integrity; `lean4export` cross-machine determinism and external-checker wall-clock are open (external checkers can be ">100× slower than Lean"). Rejected as v1 because it needs a determinism + wall-clock pilot first; retained as the Phase-3 upgrade.

### Option 3: Client-attested verification + cheap central re-check, as literally scoped (Rejected — collapses into Option 1 once made sound)
The SPEC-030-A §7.2 split at face value. **Cons:** the obvious implementation ("trust client oleans + leanchecker") is unsound on crafted-invalid oleans and on proofs of weakened/renamed statements (ADR-011 vacuity class). The fix — central source re-elaboration + statement re-derivation — *is* Option 1. Rejected for shipping the latent footgun rather than the fix.

### Option 4: BYO self-hosted GitHub Actions runners (Rejected)
Donated compute, GitHub-orchestrated. **Cons:** gating failure on a public repo — because `gate-a.yml` triggers `on: pull_request`, a fork PR would run the PR head's own gate on contributor-controlled hardware (forged green Gate A), plus classic self-hosted persistence/poisoning and fork-PR RCE risk. Sound only by re-adding a central kernel replay, at which point Option 1 dominates without the self-hosted liabilities.

### Option 5: Probabilistic spot-audit + reputation / economic disincentive (Rejected)
Trust client attestation, re-verify a random fraction, penalise on detected cheating. **Cons:** any audit rate p < 1 admits a `1 − p` fraction with no trusted re-check, making penalties load-bearing for correctness (violates the invariants and ADR-007) and assuming a merely rational adversary with a penalisable identity. Lean's re-check is cheap enough to run at p = 1; spot-checking is appropriate only for the *expensive elaboration* layer as a cost optimisation, never the kernel layer.

### Option 6: Redundant N-of-M peer re-verification (BOINC/SETI CONSENSUS tier) (Rejected)
Replicate each unit across K independent clients; accept on quorum + reputation. **Cons:** quorum among non-cryptographic identities (ADR-007) is a defeatable vote, not a kernel proof. ADR-030 reserves CONSENSUS for domains with no cheap verifier; Lean is VERIFIED, where one valid result is ground truth. Adds 200–300 % wasted client compute to obtain what a single ~10–30 s central replay settles deterministically.

### Option 7: TEE / hardware-attested runner (Rejected)
Run Gate A in an enclave that emits a hardware-signed attestation of unmodified code. **Cons:** the contributor owns the hardware and has physical access — out of TEE scope; the research surfaced practical sub-$1000 attestation-key extraction. Attestation proves code integrity relative to trusting the silicon vendor, not mathematical correctness (the load-bearing-attestation anti-pattern ADR-007 forbids). Unavailable on much consumer hardware (re-centralises to cloud CVMs); a ~20 GB replay does not fit comfortably in an enclave; rendered redundant by the cheap central re-check.

### Option 8: Centralised managed runners (baseline / control) (Rejected — it is the problem)
Keep namespace.so; scale by paying. **Pros:** unimpeachable soundness (kernel on fully-trusted ground); simplest; lowest latency. **Cons:** solves none of #635 — 0 % heavy compute leaves central infra, cost linear with no asymptote, capacity does not grow with the swarm, and an adversary's heavy PRs burn paid minutes. The yardstick to beat, not a destination.

## Dependencies

| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-006 | Gate A Soundness Enforcement | The re-check this decision relocates/scopes is Gate A's. |
| Depends On | ADR-011 | Statement-Binding Gate | Central statement re-derivation + defeq binding kills the vacuity class. |
| Depends On | ADR-018 | Goal Statement Immutability | Canonical goal source is the trusted root the statement is re-derived from. |
| Depends On | ADR-033 | Incremental Kernel Replay | Supplies the changed-module reverse-import closure and the byte-identical-rebuild invariant. |
| Depends On | ADR-045 | Gate A Library Build Cache | Verified-on-`main` olean cache for the unchanged remainder of the build. |
| Aligns With | ADR-048 | Verify-on-Ingest | The central PR-time re-check is the ingest verification; later trust is carried by provenance + immutability. |
| Constrained By | ADR-002 | Lean 4 + mathlib Pinned to Release Tags | Determinism precondition that makes offload sound. |
| Constrained By | ADR-007 | Agent Identity and Budgets | Identity/reputation stay hygiene; never load-bearing for soundness. |
| Constrained By | ADR-019 | CI Supply-Chain Protection | The `gate-a.yml` control flow is TCB; the change is CODEOWNERS-gated and SHA-pinned. |
| Realises | ADR-030 | Distributed-Workload Engine | Instantiates the SPEC-030-A §7.2 "central CI cost & DoS" prior; Lean stays VERIFIED tier. |
| Relates To | ADR-005 | Autonomous Merge Policy | The central verdict remains the single required check auto-merge keys on. |
| Informed By | [#942](https://github.com/agenticsnz/unsorry/issues/942) | Phase 1 central-build cost measurement (closed) | Measurement complete: Phase 1 not pursued — the savings it targets are already captured by ADR-033/045 (SPEC-049-A §5.6). |

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Decentralised CI runner architecture — options & recommendation | Research proposal | ../proposals/decentralised-ci-runner-architecture.md |
| REF-2 | Decentralised CI runner architecture (implementation contract) | Specification | specs/SPEC-049-A-Decentralised-CI-Runner-Architecture.md |
| REF-3 | Research: Decentralised CI runner architecture | Issue | GitHub issue #635 |
| REF-4 | Distributed-Workload Engine — Plugin Seam (§7.2 central CI cost & DoS) | Specification | specs/SPEC-030-A-Distributed-Workload-Engine.md |
| REF-5 | Gate A Workflow | Specification | specs/SPEC-006-B-Gate-A-Workflow.md |
| REF-6 | Validating a Lean Proof (leanchecker / export-format re-check) | External | <https://lean-lang.org/doc/reference/latest/ValidatingProofs/> |
| REF-7 | lean4export — self-contained NDJSON declaration export | External | <https://github.com/leanprover/lean4export> |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-15 |
| Accepted (Phase 0 delivered, #926) | unsorry maintainers | 2026-06-15 |
| Amended (Phase 1 closed — not pursued, #942) | unsorry maintainers | 2026-06-15 |
