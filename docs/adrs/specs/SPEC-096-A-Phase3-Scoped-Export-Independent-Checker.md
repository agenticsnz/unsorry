# SPEC-096-A: Phase 3 — Scoped-Export + Independent-Checker Anchor

Implements: [ADR-096](../ADR-096-Phase3-Scoped-Export-Independent-Checker.md) · builds on [SPEC-049-A](SPEC-049-A-Decentralised-CI-Runner-Architecture.md) / [SPEC-093-A](SPEC-093-A-Lean4export-Nanoda-Independent-Checker-Pilot.md) · Status: Draft (pre-acceptance) · Updated: 2026-06-25

Contract for the Phase-3a **kernel-diverse verification anchor**: declaration-scoped
`lean4export` + an independent checker (`nanoda`), run as a **non-gating** defense-in-depth
pass strictly subordinate to ADR-049's `p = 1` Lean gate. It is a **draft** because
ADR-096 is Proposed and the §4 acceptance gates are not yet all green.

## 1. The check (per proof)

For a promoted proof in library module `Unsorry.Foo` defining theorem `t`:

1. **Scoped export** — `lake env lean4export Unsorry.Foo -- t` → an NDJSON export of `t`
   plus its transitive *declaration* closure (the lemmas it actually uses), **not** the
   module's `import Mathlib` closure. Measured 2.7–46.5 MB vs ~5.9 GB whole-module.
2. **Independent re-check** — run the pinned independent checker over the export with a
   config permitting the audit whitelist `{propext, Classical.choice, Quot.sound}` +
   `Lean.trustCompiler`, `nat_extension`/`string_extension` enabled, and **`pp_declars: [t]`
   + `unknown_pp_declar_hard_error: true`** so the checker hard-errors unless `t` is present
   in the checked environment (positive control — guards a deps-only export).
3. **Record** — the verdict (accept/reject), the declaration count, wall-clock, and
   **agreement with `leanchecker`** (which already ran at the `p = 1` gate). Agreement is
   an auditable signal; a disagreement is an alert, never a merge action.

## 2. The load-bearing invariant (normative — inherited)

`leanchecker`-on-locally-rebuilt-environment remains the **sole `p = 1` truth oracle** at
the promotion boundary (SPEC-049-A §2/§4 unchanged). The independent-checker verdict is
**advisory**: it gates nothing, admits nothing, and never reduces or substitutes for the
Lean gate. A code path that lets the independent checker admit content — or that lowers
central `p < 1` — is **out of scope** (ADR-096 Phase 3c, a separate ADR amending ADR-049).
The export and its verdict are *outputs/evidence*, never trusted inputs to the gate (the
SPEC-049-A §2 no-artifact-into-the-gate invariant holds).

## 3. Soundness controls (the pilot harness, promoted to the contract)

The pilot driver (`tools/pilot/export_checker_pilot.py`) is the reference implementation of
the controls; the anchor reuses them:

- **Positive control** — `pp_declars` + `unknown_pp_declar_hard_error`: an `ok` verdict
  means the target theorem was actually in the checked environment (20/20 in the pilot).
- **Negative control** — `swap_two_theorem_values`: swap two differently-typed theorems'
  proof `value`s → a well-formed-but-ill-typed export (proof term ≠ claimed statement). The
  checker **MUST reject** it (5/5 in the pilot). An *accept* is a soundness failure.
- **Determinism** — re-export and compare sha256 (same-runner stable 38/38; cross-machine
  is §4 gate 3).

## 4. Acceptance gates (Phase 3a is disabled until all green)

1. **Broader red-team** *(implemented — `tools/pilot` `red_team_suite`, `--red-team`; hermetic
   tests in `tools/pilot/tests`; live confirmation via the pilot workflow `red_team=true`)*.
   Beyond the value-swap, the checker must REJECT each class:
   - **`type-swap`** — swap two theorems' claimed `type` (keep proofs): the export asserts a
     statement the proof doesn't prove (the *altered-statement* direction).
   - **`dangling-ref`** — repoint a proof `value` at an out-of-range Expr index: a
     **structurally-corrupt** export a rubber-stamp checker would pass.
   - **`axiom-restrict`** — run the VALID export with an **empty** permitted-axiom set and
     `unpermitted_axiom_hard_error`: any axiom use is rejected. This is the enforcement path
     that also stops **axiom-sneaking** (a sneaked `sorryAx` not in the whitelist); an
     axiom-free proof yields `n/a`, not a pass/fail.

   **Honest boundary (normative).** Genuine **weakened-statement *vacuity*** — a *well-typed*
   proof of a genuinely weaker statement that is passed off as the goal — is **NOT** catchable
   by a kernel checker: the export's `type` *is* that weaker statement and the proof *is* valid
   for it, so nanoda correctly ACCEPTS. Catching "valid proof of the wrong/weaker goal" is the
   **ADR-011 `*Binding` gate's** job (it checks statement == goal), and remains so under
   Phase 3b. `type-swap` exercises the kernel's type-matching, but is not a substitute for the
   binding gate on true vacuity. So the binding gate is a **non-negotiable companion** to any
   nanoda-as-gate placement (§ Phase 3b), not something nanoda replaces.
2. **Checker code/soundness review** *(addressed for co-gate use —
   [docs/adrs/reviews/nanoda-soundness-review.md](reviews/nanoda-soundness-review.md))*. nanoda
   is **pinned** to the reviewed commit `f58f2f6` (0.4.10-beta) in `setup.sh` + the pilot
   workflow (no longer master HEAD). Verdict: a **genuine independent type-checker** (infers
   value-type, checks def-eq vs declared type — `tc.rs:92-93`; enforces the axiom whitelist —
   `parser.rs:445-448,752-755`; reconstructs recursors), **qualified yes for a co-gate**. The
   review's three operational requirements are honoured: our wrapper treats any non-zero exit
   as a rejected verdict (`classify_checker`); we never set `unsafe_permit_all_axioms`; and the
   `nat`/`string` extensions we enable are covered by the companion `leanchecker` (the real
   Lean kernel). Residual items (inductive-checker depth, export-format TCB, fuzz corpus) are
   the audit backlog that gates any *sole-oracle* use — they do **not** block co-gating.
   If/when nanoda becomes load-bearing it enters the ADR-019 CODEOWNERS trust surface.
3. **Cross-machine determinism** — same module exported on two distinct runners hashes
   identically (required only if export-hash is used as a cross-machine oracle).
4. **Hardest-proof stress** — scoped-export size + checker wall-clock stay tractable on the
   deepest library proofs (pilot trend: 12,195 decls → 46 MB → 2.6 s).

## 5. Conformance (for the eventual implementation)

- **Non-gating guard** — a test asserts no required check `needs:` the anchor and the anchor
  workflow admits no content (no write to `library/`, no merge), mirroring SPEC-093-A §6.
- **Negative-control regression** — the red-team mutation suite (§4.1) is a standing test:
  the checker must reject every invalid class; a regression that accepts one fails CI.
- **Pin discipline** — `lean4export` and the checker are pinned to the `lean-toolchain` tag
  (ADR-002); a toolchain bump updates both in a dedicated PR.

## 5a. Contributor-side entry — the `run.sh` switch (shipped)

The first production placement is **contributor-side and advisory**, the lowest-risk way
to run the anchor on real swarm proofs at scale (ADR-096 Phase 3a). It is **untrusted**
(ADR-049) and therefore can never be load-bearing — which is exactly what makes it safe and
additive.

- **Default & switch:** the check is **ON BY DEFAULT** in the client entry scripts
  (`swarm/run.sh` and a standalone `swarm/supervise.sh`). Opt out with
  `--no-independent-check` (alias `--no-nanoda`) or by setting
  `UNSORRY_INDEPENDENT_CHECK` to a falsey value (the latter lets infra/CI disable it without
  changing args). The entry scripts bootstrap the tools on first use (build lean4export +
  nanoda; Rust auto-installs via rustup if absent), then export
  `UNSORRY_INDEPENDENT_CHECK`/`LEAN4EXPORT_BIN`/`NANODA_BIN` so the decision propagates to
  `agent.sh` (which reads `UNSORRY_INDEPENDENT_CHECK` via `env_truthy`). run.sh sets the var
  to `0`/`1` explicitly so supervise.sh never re-enables an opt-out. Default-on stays
  **non-gating** — a failed bootstrap or any error degrades to a logged skip; proving is
  never blocked. (It was opt-in in the first cut; flipped to default-on once the mechanism
  was demonstrated end-to-end.)
- **Hook:** `swarm/agent.sh::independent_check_advisory` runs **after** a proof passes
  `prove_local_verify` (and after ADR-074 import minimisation), mirroring
  `minimize_proof_imports`'s best-effort pattern. It is **non-gating and never fails the
  prove loop**: if `LEAN4EXPORT_BIN`/`NANODA_BIN` are absent or the check errors, it logs and
  returns 0.
- **Check:** `python3 -m tools.independent_check --module Unsorry.<Camel>` →
  `tools.independent_check.check_proof`, which reuses the pilot primitives (§3) for a single
  proof: declaration-scoped export → nanoda with the `pp_declars` positive-control guard →
  verdict line. A nanoda **disagreement** (it rejects a locally-accepted proof) is surfaced
  as a `::warning::`, **never a block** — soundness rests on ADR-049's `p = 1` Lean gate in
  CI, unchanged.
- **Tools:** built once via `tools/independent_check/setup.sh` (lean4export pinned to the
  `lean-toolchain` tag; nanoda from source — pin a reviewed commit before §4 gate 2). The
  dependency is the only real friction; the switch degrades to a logged skip without it.
- **Tests:** `tools/independent_check/tests/` (Python, hermetic) + an `agent.sh --self-test`
  case asserting the switch is opt-in and never invokes the tools when off or absent.

This entry gates nothing and admits nothing; it generates the agreement data and exercises
the path that the trusted-side placements (§1, and the §5b backstop) and the §4 acceptance
gates build on.

## 5b. Trusted-side entry — the scheduled backstop (shipped, observe-only)

The trusted-side placement: a **scheduled, non-required, observe-only** workflow
(`.github/workflows/independent-check-backstop.yml`) that re-checks **recently-merged library
proofs** with the same scoped-export + nanoda check. Unlike the contributor-side entry (§5a),
it does **not** depend on a local prover winning a goal — it samples whatever has landed on
`main` (including the cloud swarm's proofs), so it accrues agreement evidence at scale
regardless of the proving race. The two entries **coexist and are independent** (the
existence of one changes nothing about the other), satisfying the non-breaking requirement.

- **Trigger:** daily `schedule` + `workflow_dispatch`. **Non-required**, on no PR — it gates
  nothing and reverts nothing (a sampled proof is already merged and `leanchecker`-verified at
  `p = 1`).
- **Sample:** library modules **added to `main`** within a window (`git --since`, the newest
  proofs — what a backstop most wants to catch), capped; falls back to an even spread when the
  window is empty, so a run is never vacuous.
- **Check:** reuses `tools.pilot.export_checker_pilot --scope-decls --negative-control` (DRY)
  — declaration-scoped export → nanoda with the §3 positive control, plus the §3 negative
  control as a per-proof reject-invalid self-check. Tools built via the §5a `setup.sh`
  (dogfoods the same bootstrap).
- **Observe-only (for now).** A **disagreement** — nanoda fails to accept a main proof
  (`status != ok`, target not confirmed, or the negative control not rejected) — is surfaced
  loudly (`::warning::` + the run summary + the uploaded report) but the run **SUCCEEDS**:
  `nanoda` is `0.4.10-beta` and pre-code-review (§4 gate 2), so a beta-checker quirk must be an
  alert to investigate, **never a false red** on the schedule, and **never** a revert (ADR-049
  `p = 1` is the only oracle). Escalating a confirmed disagreement to a **failing** run is a
  deliberate follow-up, gated on the §4 acceptance gates (esp. the nanoda review) — *not* done
  here.

This is the placement whose production track record §4 / Phase 3b build on. "Step a works in
production" = the backstop runs, samples merged proofs, and produces agreement data without
false alarms; the §4 red-team (gate 1) follows once that is confirmed.

## 6. Out of scope

- Making the independent checker merge-gating (needs §4 + Phase 3b).
- Lowering central `p < 1` / sampling the promotion gate (Phase 3c — separate ADR amending
  ADR-049).
- The P2P / volunteer distribution of the anchor (ADR-053 substrate; ADR-103 validator role
  credit) — downstream once the anchor is real.
