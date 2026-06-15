# SPEC-049-A: Decentralised CI Runner — Tiered Verification Split

Implements: [ADR-049](../ADR-049-Decentralised-CI-Runner-Architecture.md) · Status: Accepted (Phase 0 delivered) · Updated: 2026-06-15

This spec defines the **contract** for the recommended decentralised CI runner architecture: a tiered split where the untrusted contributor performs the expensive elaboration and a mandatory cheap **central** re-check is the sole load-bearing soundness gate. Phase 0 is delivered (the §5 conformance suite, see §6); the **Phase-1+ control-flow change remains a design target**. Today's Gate A (ADR-006/SPEC-006-B) is the conformance reference because the central re-check already exists — this spec scopes *which work it repeats* and codifies *what it must never trust*. It is intentionally implementation-light: the full options analysis is in [docs/proposals/decentralised-ci-runner-architecture.md](../../proposals/decentralised-ci-runner-architecture.md), and the decision is [ADR-049](../ADR-049-Decentralised-CI-Runner-Architecture.md).

## 1. Roles

- **Contributor runner (untrusted).** The client that already runs `swarm/agent.sh::prove_local_verify()` — full `lake build UnsorryLibrary --wfail` elaboration + `axiom_audit` + `check_library_options` as advisory preflight. It produces the proof and an **advisory manifest**. It is never trusted; its output gates nothing.
- **Central re-check (trusted).** A project-controlled ephemeral runner (today: namespace.so; ADR-019 TCB) that produces the **only** verdict that admits content to `UnsorryLibrary`.

## 2. The load-bearing invariant (normative)

The central PR-time re-check is the ADR-048 **verify-on-ingest** event for proof PRs. It **MUST NOT** consume any contributor-supplied compiled artifact (`.olean`, exported term, attestation, hash, or manifest field) as a *trusted* input. For each PR it **MUST**, on the trusted surface:

1. **Re-derive the statement** from canonical goal source (`goals/<id>.lean` + record, ADR-018 create-only; ADR-011 binding) — never from a contributor-supplied statement.
2. **Re-elaborate the changed-module reverse-import closure from source** — the changed `library/Unsorry/*.lean` modules plus their reverse-import closure and the generated ADR-011 `*Binding` modules — against dependency oleans that are either rebuilt on trusted CI or restored from a commit-exact trusted-CI cache (ADR-045). Restored dependency oleans are allowed only when their provenance binds them to the exact base commit, Lean toolchain, Lake manifest, and prior trusted Gate A run that produced them. It **MUST NOT** `leanchecker` a contributor-supplied olean.
3. **Run the existing authoritative checks verbatim** over that closure: `leanchecker` replay (ADR-033), serialised `axiom_audit` against the whitelist `{propext, Classical.choice, Quot.sound}`, and ADR-011 defeq statement-binding of the proved term to the re-derived statement.
4. **Fall back to a full re-check** (ADR-033 global-impact rule) on any change to `lean-toolchain`, `lakefile*`, `lake-manifest.json`, or `tools/gate_a/**`.

A contributor-supplied `.olean` reaching `leanchecker` as a trusted input is a **soundness defect**, not an optimisation. Rationale (ADR-049 soundness argument): `leanchecker` trusts olean structure and replays the statement it is given, so trusting client oleans is unsound on (i) crafted-invalid oleans and (ii) real proofs of weakened/renamed statements (the ADR-011 / PR-#64 vacuity class).

## 3. Advisory manifest (hygiene, not trust)

The contributor MAY attach a manifest to the PR/claim record carrying: `toolchain` hash, `mathlib` release tag, the set of `changed_modules`, and the `goal_sha`. It is **hygiene only** — used for fast-fail pre-filters, diagnostics, and griefing metrics. The soundness gate does not depend on it; v1 soundness holds even if the manifest is absent, forged, or wrong, because §2 re-derives everything from canonical source. Any manifest parser is TCB-adjacent and lands under CODEOWNERS (ADR-019).

## 3.1 Carrying Trust Forward

After the central re-check passes, downstream archive or leaderboard flows may trust the proof only as an already-ingested artifact under ADR-048: the artifact identity, statement binding, toolchain/mathlib context, and provenance must be preserved, and any byte or trusted-context change requires re-verification. Contributor-local logs or manifests are never evidence that the artifact was ingested.

## 4. Sampling discipline

- **Soundness layer (kernel re-check, §2): p = 1.** Runs on every PR. No probabilistic acceptance, no quorum, no reputation gate. This is what keeps Lean in ADR-030's VERIFIED tier.
- **Expensive-elaboration / abuse layer: p < 1 permitted, advisory only.** Any spot-audit (random full rebuilds + all infra PRs) or peer-consensus overlay is **non-merge-gating**: it may detect drift/abuse or prioritise re-elaboration, never decide whether content lands. Making any non-kernel signal merge-gating requires a new ADR with explicit soundness analysis.

## 5. Conformance (defined for the eventual implementation, not asserted here)

1. **Soundness regression (binary, must stay green forever):** Gate A **rejects** (a) a crafted structurally-invalid `.olean`, and (b) a real, type-correct proof of a *weaker or renamed* statement than the goal demands. No code path lets a contributor-supplied `.olean` reach `leanchecker` as a trusted input.
2. **Behaviour preservation:** on a known-good proof and a known sorried module, the scoped central re-check yields the same pass / fail-closed outcome as today's full Gate A (ADR-006/SPEC-006-B).
3. **Scoping correctness:** the re-elaborated set equals the ADR-033 changed-module reverse-import closure (incl. `*Binding` modules); a global-impact change forces the full re-check.
4. **Cache provenance:** any restored dependency olean used by the central build is commit-exact, toolchain-exact, and produced by a prior trusted Gate A run; missing or mismatched provenance forces rebuild or fail-closed.
5. **Determinism:** under ADR-002 pinning, an unchanged module's olean rebuilds byte-identically (the ADR-033 invariant); divergence is a hard fail, never a silent accept.
6. **Cost measurement:** central runner-minutes per merged PR are measured baseline vs post-change; the reported saving is the elimination of the redundant unchanged-module build (honest framing per ADR-049), not a SETI-scale figure.

## 6. Phasing (contract milestones)

- **Phase 0 (delivered):** ADR-049 + this spec + the §5 conformance regression suite (`tools/gate_a/tests/test_decentralised_runner_conformance.py`), which locks in the §2 soundness invariant (no contributor-supplied artifact is a trusted input; scoping never under-scopes incl `*Binding`; global-impact forces a full re-check; the workflow feeds no downloaded artifact into the central build/replay). The Phase-1-dependent items (§5.4 cache provenance, §5.5 determinism) are recorded as skipped placeholders. No `gate-a.yml` control-flow change.
- **Phase 1 (closed — not pursued, #942):** would have scoped the central build to the changed closure. The §5.6 cost measurement showed the redundant unchanged-module build is already eliminated by ADR-033/045 — on a warm-cache CI run the once-per-PR `--wfail` build is ~41 s of a ~8 runner-min/PR gate dominated by fixed mathlib-environment loading (audit ~165 s, replay ~60 s, three cache restores), so target-narrowing buys only low-single-digit % per PR, not worth a TCB control-flow change. The §5 conformance suite (#926) remains the standing guard.
- **Phase 2:** advisory pre-filters + per-contributor rate-limiting (SPEC-030-A §7.1 anti-abuse), non-merge-gating.
- **Phase 3 (pilot-gated):** `lean4export` + independent-checker re-check as a second, kernel-diverse anchor — adopted only if a determinism + wall-clock pilot shows it bounded (guard the ">100× slower" pathology). Authoritative gate stays `leanchecker`-on-locally-rebuilt-environment until then.

## 7. Out of scope (each its own decision)

- **Artifact transport** (how/whether a contributor uploads oleans/exports) — not needed for v1 soundness, since §2 re-derives from source; a later ADR if Phase 3 wants it.
- **Anti-abuse / identity / rate-limiting** — SPEC-030-A §7.1; its own ADR (ADR-007 keeps identity advisory).
- **`lean4export` cross-machine determinism and independent-checker wall-clock** — open questions gating Phase 3 (see proposal Open Questions).
- **Dependency-cache implementation details** — storage backend, eviction, and restore mechanics are separate implementation choices, but §2.2's trusted provenance requirement is in scope for any implementation.
- **Peer-consensus / spot-audit overlay** (Phase 4) — advisory only; requires its own anti-sybil ADR.
