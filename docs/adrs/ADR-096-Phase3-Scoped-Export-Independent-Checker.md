# ADR-096: Phase 3 — Declaration-Scoped Export + Independent Checker as a Kernel-Diverse Anchor

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-096 |
| **Initiative** | verification capacity / decentralisation (Phase 3, Track B) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-25 |
| **Status** | Proposed |

## Context

ADR-049 / SPEC-049-A §6 left **Phase 3** — a cheap, portable, mathlib-free re-check via
`lean4export` + an independent checker — **pilot-gated** behind two empirical open
questions (Q2 cross-machine export determinism; Q3 independent-checker wall-clock /
no >100× pathology). ADR-093 / SPEC-093-A ran that pilot. This ADR records the
**decision that follows from the pilot data**: the mechanism that makes Phase 3 real
and the conservative way to adopt it.

The pilot (issue #5684, runs 1–7) established, on the live library:

- **The blocker was the export shape, not the tooling.** A *whole-module* export is
  ~5.9 GB because each `Unsorry.*` module is `import Mathlib` — it drags in all of
  mathlib. A **declaration-scoped** export (`lean4export Module -- <theorem>`) of the
  proof's own theorem + its transitive *declaration* closure is **2.7–46.5 MB**
  (126×–2194× smaller).
- **Independent checking is fast and bounded (Q3).** `nanoda` (an independent Rust
  Lean kernel) checks a scoped export in **0.08–2.6 s** — **4×–160× faster** than
  `leanchecker`, which pays a fixed full-environment cost. No >100× pathology.
- **Export is deterministic (Q2, same-runner).** 38/38 exports byte-identical across
  re-runs. (Cross-*machine* determinism is still to confirm — see acceptance gates.)
- **It accepts valid proofs (positive control).** 20/20 modules: nanoda accepted the
  scoped export *and* the target theorem was confirmed present in the checked
  environment (via `pp_declars` + `unknown_pp_declar_hard_error`).
- **It rejects invalid proofs (negative control).** 5/5 modules: nanoda **rejected** a
  deliberately ill-typed export (two theorems' proof `value`s swapped, so a proof term
  no longer matches its claimed statement — the SPEC-049-A "claims X, proves Y" /
  weakened-statement class). nanoda genuinely type-checks; it does not rubber-stamp.

So the Phase-3 mechanism is now **empirically demonstrated**: scoped-export + an
independent checker is a *cheap, portable, mathlib-free, sound-on-tested-cases,
fast* verification of a proof. What remains is *breadth of validation*, not *whether
the door is open*.

## WH(Y) Decision Statement

**In the context of** ADR-049's Phase 3 (the only verification-throughput
*slope*-changer — a re-check that needs no mathlib resident and so parallelises and
ports without bound), pilot-gated behind Q2/Q3, where the ADR-093 pilot has now
shown that a **declaration-scoped** `lean4export` (2.7–46.5 MB, not 5.9 GB) checked
by an **independent kernel** (`nanoda`) is deterministic, fast (4×–160× faster than
`leanchecker`), accepts valid proofs (target-confirmed), and **rejects ill-typed
ones** (negative control 5/5),

**facing** the fact that this is strong but *bounded* evidence — one invalid class
tested, a `0.4.10-beta` checker not yet code-reviewed, cross-*machine* determinism
unconfirmed, and only sourced-tier proofs sampled — so adopting it as a *gating* or
*p < 1* mechanism now would over-trust the data,

**we decided for** **adopting the declaration-scoped-export + independent-checker
mechanism as Phase 3's validated direction, introduced conservatively as a
non-gating, kernel-diverse defense-in-depth anchor** (Phase 3a): a scheduled /
sampled second check that exports each promoted proof's declaration closure and
re-verifies it with an independent checker, recording agreement with `leanchecker`
as an auditable signal — **strictly subordinate to ADR-049**: the Lean kernel via
`leanchecker`-on-locally-rebuilt-environment remains the **sole `p = 1` truth oracle**
at the promotion boundary; the independent checker is **additive, never a
replacement**, and gates nothing,

**and neglected** (a) making the independent checker *merge-gating* now (rejected —
SPEC-049-A §4: a non-kernel signal is advisory until proven across the full red-team
and a checker code review; premature on one invalid class + a beta checker); (b)
lowering the central re-check below `p = 1` / sampling the promotion gate (rejected
and **explicitly out of scope** — a separate ADR amending ADR-049's `p = 1`
invariant, gated on this anchor's production track record); (c) whole-module export
(rejected — the ~5.9 GB artifact that made Phase 3 look infeasible; declaration
scoping is the load-bearing insight); and (d) treating "nanoda is fast + accepts
valid proofs" as sufficient (rejected — the negative control was the make-or-break
test, and broader red-team + a checker review remain acceptance gates),

**to achieve** the first concrete, evidence-backed step toward Phase 3 — a
kernel-*diverse* verification anchor (a proof both Lean and an independent kernel
accept is stronger evidence, guarding a hypothetical bug in either) that is also the
**groundwork for the eventual cheap portable gate** — without taking on the soundness
risk of gating on an under-validated checker,

**accepting that** an independent checker introduces a new dependency to maintain and
pin (it must track the toolchain, ADR-002); that the anchor spends some compute on
defense-in-depth that admits no proofs; that the strong pilot result is on
sourced-tier proofs and one invalid class, so the acceptance gates below (broader
red-team, checker code review, cross-machine determinism, hardest-proof stress) must
pass before any move toward gating; and that `p = 1` on the trusted Lean gate is
unchanged and non-negotiable here (ADR-049).

## Phasing

- **Phase 3a — kernel-diverse anchor (this ADR; non-gating).** Scoped-export +
  independent-checker re-check runs as a scheduled / sampled defense-in-depth pass;
  agreement with `leanchecker` is recorded and audited. Gates nothing. Adopted once
  the acceptance gates below are green.
- **Phase 3b — portable cheap gate (future ADR).** Once the anchor has a production
  track record, the scoped-export + independent-checker becomes a *portable* form of
  the `p = 1` gate (runnable off the mathlib-resident lane), cutting central cost —
  still `p = 1`, still kernel-authoritative.
- **Phase 3c — sampling central `p < 1` (separate ADR amending ADR-049).** Explicitly
  **out of scope here**; requires its own decision and the anchor's reputation data.

## Acceptance gates (must pass before Phase 3a is enabled)

1. **Broader red-team.** Beyond the value-swap (type-mismatch) class: structurally-
   corrupt exports, the same-name weakened-statement vacuity (the ADR-011 / PR-#64
   class), and axiom-sneaking (a `sorryAx`-bearing export with `sorryAx` *not*
   permitted must be rejected). The independent checker must reject **every** class.
2. **Independent-checker code/soundness review.** `nanoda` is `0.4.10-beta`;
   behavioural agreement + reject-invalid is strong evidence, not a substitute for a
   review of the checker itself, and it enters the ADR-019 trust surface if it ever
   becomes load-bearing.
3. **Cross-machine determinism (true Q2).** Export the same module on two distinct
   runners and confirm byte/hash identity — required if export-hash is ever used as a
   cross-machine oracle (not required for the "ship export, re-check anywhere" use,
   where the *check* is the oracle, not the hash).
4. **Hardest-proof stress.** The sample is sourced-tier; confirm scoped-export size +
   checker wall-clock stay tractable on the deepest library proofs (the trend is
   strongly favourable: a 12,195-declaration proof exported to 46 MB and checked in
   2.6 s).

## Consequences

- **Positive.** Phase 3's mechanism is decided on evidence; unsorry gains a
  kernel-*diverse* verification anchor (defense-in-depth against a kernel bug) and the
  groundwork for a cheaper portable gate — the path to the throughput slope-changer.
- **Positive.** Zero soundness risk on adoption: non-gating, `p = 1` Lean gate
  unchanged, independent checker additive.
- **Negative.** A new pinned dependency (the independent checker) and some compute
  spent on defense-in-depth. Phase 3a is gated behind four acceptance validations, so
  the throughput win (3b/3c) is still a few steps out.
- **Negative.** If the broader red-team or the checker review fails, the anchor stays
  advisory-only or is dropped — the pilot evidence is necessary, not sufficient, for
  gating.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Phase-3 scoped-export + independent-checker spec | Specification | specs/SPEC-096-A-Phase3-Scoped-Export-Independent-Checker.md |
| REF-2 | lean4export + nanoda pilot | Decision | ADR-093-Lean4export-Nanoda-Independent-Checker-Pilot.md |
| REF-3 | Decentralised CI Runner Architecture (Phase 3, p=1 invariant) | Decision | ADR-049-Decentralised-CI-Runner-Architecture.md |
| REF-4 | Decentralised CI Runner — tiered split / Phase 3 open questions | Specification | specs/SPEC-049-A-Decentralised-CI-Runner-Architecture.md |
| REF-5 | Sharded Gate A Axiom Audit (Track A, shipped) | Decision | ADR-091-Sharded-Gate-A-Axiom-Audit.md |
| REF-6 | CI supply-chain protection (trust surface) | Decision | ADR-019-CI-Supply-Chain-Protection.md |
| REF-7 | Verification-throughput roadmap | Discussion | GitHub discussion #5656 |
| REF-8 | D2 pilot — full run record | Issue | GitHub issue #5684 (roadmap #5678) |
| REF-9 | lean4export | External | https://github.com/leanprover/lean4export |
| REF-10 | nanoda independent Lean checker | External | https://github.com/ammkrn/nanoda_lib |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-25 |
