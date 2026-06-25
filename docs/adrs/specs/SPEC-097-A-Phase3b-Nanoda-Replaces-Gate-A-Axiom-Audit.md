# SPEC-097-A: Phase 3b — nanoda replaces the Gate A axiom audit

Implements: [ADR-097](../ADR-097-Phase3b-Nanoda-Replaces-Gate-A-Axiom-Audit.md) · builds on
[SPEC-096-A](SPEC-096-A-Phase3-Scoped-Export-Independent-Checker.md) /
[SPEC-091-A](SPEC-091-A-Sharded-Gate-A-Axiom-Audit.md) · Status: Draft · Updated: 2026-06-25

Contract for replacing the Gate A `axiom_audit` with a **nanoda scoped-export check** while the
`leanchecker` replay stays the **`p = 1`** kernel oracle (ADR-049, unchanged).

## 1. The `gate_a_nanoda` job

For the PR's changed library proof(s) `Unsorry.Foo` (theorem `t`, with its ADR-011 `*Binding`):

1. **Build** the library (reuse `gate_a_prepare`'s warm `.lake`; same restore the audit/replay
   shards use — SPEC-091-A §2).
2. **Scoped export** `lake env lean4export Unsorry.Foo -- <t and its *Binding decls>` →
   declaration-scoped NDJSON (the proof's transitive *declaration* closure).
3. **nanoda** (pinned `f58f2f6`) over the export with: the audit whitelist
   `{propext, Classical.choice, Quot.sound, Lean.trustCompiler}`, **`unpermitted_axiom_hard_error:
   true`** (so any other axiom — incl. `sorryAx` — fails), `nat_extension`/`string_extension:
   true`, and **`pp_declars: [t, tBinding]` + `unknown_pp_declar_hard_error: true`** (the target
   theorems must be present in the checked env — guards a deps-only export).
4. **Verdict → gate:** nanoda exit 0 ⇒ pass; any non-zero (reject / panic / timeout) ⇒ **fail**
   (`classify_checker`: non-ok is always a gate failure — never a silent pass).

## 2. Coverage equivalence (normative — must hold before cutover)

The check must cover **everything `axiom_audit` covered** for the change:

- **Axiom footprint** — nanoda over the scoped closure enforces `axioms ⊆ whitelist` transitively
  (the export carries the full declaration closure), so it rejects exactly what the audit
  rejected (non-whitelisted axiom, `sorryAx`/sorry).
- **Target presence** — the `pp_declars` positive control proves `t` (and `tBinding`) are in the
  checked environment (no degenerate deps-only pass).
- **Scope** — unsorry proofs are **leaves** (each fills its own module's sorry; no shared-module
  mutation), so the changed set is the proof module; the scoped export of `{t, tBinding}` and
  closure equals the audit's per-PR target set. A change that is **not** a leaf proof (touches a
  shared module / forces a broader audit scope — `forces_full_audit`, SPEC-091-A) **falls back to
  the real `axiom_audit`** (fail-closed): `gate_a_nanoda` only claims the leaf-proof case.

## 3. What is explicitly NOT changed

- **`p = 1` kernel oracle.** `gate_a_replay` (leanchecker, ADR-063) runs unchanged on every PR.
  This SPEC does not touch ADR-049 §2/§4. nanoda's kernel check is additive diversity.
- **ADR-011 binding gate.** The binding-presence/correctness check stays; nanoda additionally
  type-checks `tBinding`. Vacuity remains the binding gate's job (SPEC-096-A §4.1).
- **`gate-a` required context name** (ADR-058) — unchanged across the cutover.

## 4. Defense-in-depth (retained)

- **Daily full `axiom_audit` backstop** on `main` (ADR-048) — catches any nanoda
  axiom-under-enforcement within 24 h.
- **Sampled per-PR real audit** — the real `axiom_audit` still runs on a fraction of PRs
  (`vars.UNSORRY_AUDIT_SAMPLE`, default 0.1) alongside nanoda during bed-in, for fast
  bug-detection; a disagreement is loud and blocks that PR.

## 5. Cutover (staged, conformance-gated)

- **3b.1a (non-required).** `gate_a_nanoda` runs alongside `gate_a_audit`; the aggregator does
  **not** yet `need` it. Records agreement; zero risk. A conformance test asserts no required
  check `needs: gate_a_nanoda` in this stage.
- **3b.1b (cutover, explicit maintainer go).** Aggregator `needs:` swaps `gate_a_audit` →
  `gate_a_nanoda` (+ the sampled audit + the leaf/non-leaf router); `gate_a_audit` matrix is
  removed from the required path (kept for the daily backstop + sampling). Conformance updated to
  assert: `gate-a` context unchanged; daily full-audit backstop present; nanoda pinned (no master
  HEAD); `gate_a_nanoda` feeds nanoda only locally-derived module names (ADR-049 no-client-artifact).

## 6. Conformance (standing tests)

- nanoda **pin discipline**: `setup.sh` + every workflow build a fixed commit, never master HEAD
  (a `git clone … --depth 1 <repo>` without a pinned SHA fails the test).
- **fail-closed**: `gate_a_nanoda` non-leaf / export-failure / nanoda-non-ok all map to a gate
  failure, never a skip-pass.
- **backstop present**: the daily full `axiom_audit` job exists and is scheduled.
- the SPEC-096-A §4.1 red-team mutation suite remains a standing regression (the checker must keep
  rejecting every invalid class).
