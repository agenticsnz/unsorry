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

1. **Broader red-team** — the checker rejects, in addition to value-swap: structurally-
   corrupt exports; the same-name **weakened-statement** vacuity (ADR-011 / PR-#64 class);
   and **axiom-sneaking** (a `sorryAx`-bearing export with `sorryAx` not permitted is
   rejected). Add each as a negative-control mutation in the pilot harness.
2. **Checker code/soundness review** — a review of the independent checker itself
   (`nanoda 0.4.10-beta`), pinned to a reviewed commit; if it ever becomes load-bearing it
   enters the ADR-019 CODEOWNERS trust surface.
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

## 6. Out of scope

- Making the independent checker merge-gating (needs §4 + Phase 3b).
- Lowering central `p < 1` / sampling the promotion gate (Phase 3c — separate ADR amending
  ADR-049).
- The P2P / volunteer distribution of the anchor (ADR-053 substrate; ADR-086 validator role
  credit) — downstream once the anchor is real.
