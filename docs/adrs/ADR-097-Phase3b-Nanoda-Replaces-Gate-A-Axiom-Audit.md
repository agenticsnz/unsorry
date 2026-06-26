# ADR-097: Phase 3b — Replace the Gate A Axiom Audit with the nanoda Scoped-Export Check (p=1 preserved)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-097 |
| **Initiative** | verification throughput (Phase 3b, Track B) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-25 |
| **Status** | Proposed |

## Context

The Gate A throughput ceiling is a flat **~24 proof-merges/h**, **Namespace-runner-capacity
bound** (not backlog). The dominant per-PR cost is the **axiom audit**: ~55–65% of the
~10–12 runner-min/green-PR, sharded across **8 concurrent runners** (ADR-091). So the audit
is both the wall-clock long pole *and* the biggest consumer of the fixed concurrency budget
that sets the ceiling.

ADR-096 (Phase 3a) established the **scoped-export + nanoda** mechanism and ran it as a
**non-gating** anchor. Its acceptance gates are now cleared for **load-bearing axiom-footprint
use** (NOT yet sole-kernel-oracle use):

- **Gate 1 (broader red-team)** — nanoda rejects value-swap, **type-swap**, **dangling-ref**,
  and **axiom-restrict** (empty whitelist → any axiom rejected) on diverse real proofs
  (SPEC-096-A §4.1; live run).
- **Gate 2 (soundness review + pin)** — nanoda is a genuine independent type-checker that
  **enforces the axiom whitelist** (`parser.rs:445-448,752-755`); pinned to `f58f2f6`
  (`docs/adrs/reviews/nanoda-soundness-review.md`). Verdict: qualified yes.
- **Gate 3** N/A (no cross-machine export-hash oracle). **Gate 4** met (12,187-decl / 46 MB
  proof checked in 1.75 s).

The crucial observation: **nanoda over a scoped export does the axiom audit's job** — it
enforces `axioms ⊆ {propext, Classical.choice, Quot.sound}` and **rejects a sneaked `sorryAx`**
— in **~seconds on one runner**, and kernel-type-checks the closure as a bonus.

## Decision

**Replace the Gate A `axiom_audit` job with a nanoda scoped-export check; keep the
`leanchecker` kernel replay at `p = 1` unchanged.**

1. A new Gate A job (`gate_a_nanoda`) exports the PR's changed proof declarations
   (declaration-scoped `lean4export`) and runs the **pinned** nanoda with the audit whitelist
   + `unpermitted_axiom_hard_error: true` + the `pp_declars` positive control. A non-ok
   verdict **fails the gate**.
2. The **`gate_a_audit` 8-shard `axiom_audit` is removed from the required set.** Its sole
   purpose — axiom-footprint enforcement — is subsumed by (1).
3. **`leanchecker` replay (`gate_a_replay`, ADR-063) stays, at `p = 1`.** This ADR does **NOT**
   amend ADR-049's invariant: every promoted proof is still kernel-re-checked by Lean's own
   checker. We are replacing the **axiom-footprint** check, not the kernel oracle. nanoda's
   kernel check is **additive TCB diversity** alongside leanchecker, never a substitute.
4. The **ADR-011 binding gate is retained** — nanoda type-checks the `*Binding` theorem in the
   scoped export (confirming the proof's statement is defeq to the goal's), and the
   binding-*presence* check stays. Per the gate-2 review, *vacuity* (a valid proof of a weaker
   goal) is the binding gate's responsibility, not the kernel checker's; this ADR does not
   touch it.
5. **Defense-in-depth retained:** the daily full `axiom_audit` backstop (ADR-048 Phase 2)
   keeps running on `main`, so any nanoda axiom-under-enforcement is caught within 24 h; plus a
   **sampled (`p_audit < 1`) real `axiom_audit`** runs per-PR alongside nanoda for fast
   bug-detection during bed-in (knob `vars.UNSORRY_AUDIT_SAMPLE`, default e.g. 0.1).

## Consequences

**Throughput (the win).** Per-PR runner footprint roughly **halves** — the 8 audit shards
collapse to 1 nanoda runner. With the fixed Namespace concurrency budget that sets the ceiling,
~halving per-PR runners ~**doubles PRs-in-flight → ~2× the merge-rate ceiling**, plus the audit
wall-clock (~5.5 min) drops to nanoda+export (~seconds–1 min). This is a real needle-move while
keeping `p = 1`. The *remaining* path to ~3–4× — sampling/replacing the **leanchecker replay**
at `p < 1` — is **Phase 3c, a separate ADR amending ADR-049**, explicitly **out of scope here**.

**Soundness.** The `p = 1` kernel truth oracle (leanchecker replay) is unchanged, so kernel
soundness is not on nanoda. What becomes **load-bearing** is nanoda's **axiom-footprint
enforcement** (a nanoda bug that missed a `sorryAx` would let a sorried proof pass the axiom
check — though leanchecker replay would still kernel-verify it). Mitigations: gates 1–2
validated exactly this path; the daily full-audit backstop + the sampled per-PR real-audit
catch any miss. nanoda therefore **enters the ADR-019 CODEOWNERS trust surface**.

**Trust surface.** `gate_a_nanoda`, `setup.sh`/the nanoda pin, and the export-checker driver
join the CODEOWNERS-reviewed gate tooling.

## Staged rollout (each its own PR, ADR-058 pilot discipline)

- **3b.1a — observe.** Add `gate_a_nanoda` as a **non-required** job running alongside the
  audit on real PR traffic; record agreement. Zero risk (audit still gates).
- **3b.1b — cutover.** Once 3b.1a shows sustained agreement at scale: make `gate_a_nanoda`
  **required**, drop `gate_a_audit` from the required set (keep the daily backstop + sampled
  real-audit), `gate-a` context name unchanged. **Needs explicit maintainer go** (required-gate
  trust-surface change).

## Alternatives considered

- **Replace audit AND replay (nanoda sole gate).** Rejected: betting kernel soundness on an
  unaudited `0.4.10-beta` checker (gate-2 residual). Keeping leanchecker at `p=1` is the safe
  posture and still wins.
- **Sample leanchecker now (`p<1`).** Deferred to Phase 3c — it amends ADR-049's core invariant
  and should follow a nanoda production track record, not precede it.
- **Keep the audit, add nanoda as pure diversity.** No throughput gain (the audit cost stays) —
  fails the #5678 goal.

## References

ADR-096/SPEC-096-A (Phase 3a anchor), ADR-091 (sharded audit being replaced), ADR-063 (replay,
retained), ADR-049/SPEC-049-A (`p=1` invariant, **unchanged**), ADR-011 (binding gate,
retained), ADR-048 (daily backstop), ADR-058 (runner roles / required-context discipline),
ADR-019 (CODEOWNERS trust surface). Roadmap #5678; tracking #5684.
