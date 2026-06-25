# ADR-093: lean4export + nanoda Independent-Checker Pilot

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-093 |
| **Initiative** | verification capacity / decentralisation (Phase 3, Track B) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-24 |
| **Status** | Proposed |

## Context

Discussion #5656 and the roadmap (#5678 / #5684) frame the verification-throughput
problem as three tracks. **Track A** (capacity/latency) is shipping — D1a sharded
the Gate A axiom audit (ADR-091, v1.33.0), and its production measurement confirmed
the predicted result: Track A **buys latency, not slope**. Median per-PR audit
wall-clock fell ~34%, but steady-state throughput stayed flat because it is bounded
by Namespace runner-minute capacity, which sharding parallelises rather than
reduces. The only path that changes the *slope* — making the central gate scale
with the swarm instead of the Namespace bill — is **Track B / Phase 3**: a cheap,
portable, mathlib-free re-check.

ADR-049 / SPEC-049-A §6 specify Phase 3 as **pilot-gated** behind two empirical
open questions, deliberately *not* decided until measured:

- **Q2 (determinism):** does `lean4export` produce **hash-stable** output across
  machines for a fixed module + toolchain? If yes, export-hash equality is a valid
  cross-machine oracle; if no, export is only tamper-evidence/dedup and Phase-3-as-
  decentralisation is dead.
- **Q3 (wall-clock):** is an independent checker's (`nanoda`) re-check time
  **bounded**, with **no >100× pathology** vs `leanchecker`? This gates whether the
  export path can ever be a *second, kernel-diverse anchor* rather than advisory-only.

These are **empirical** — they cannot be answered by analysis, only by running the
tools on real unsorry declaration closures. No pilot harness exists yet.

A feasibility scout (2026-06-24) confirms the pilot is viable: the project pins
**Lean v4.30.0**, and **`lean4export` ships a `v4.30.0` tag — an exact match**, so Q2
is directly testable; `nanoda_lib` is actively maintained (last push 2026-06-03),
and its compatibility with the current export format is itself part of what Q3
measures.

## WH(Y) Decision Statement

**In the context of** Track A (D1a) having shipped and confirmed that sharding buys
latency but not throughput-slope (the ceiling is Namespace capacity), so the only
slope-changer is a cheap mathlib-free central re-check (Phase 3), which ADR-049 /
SPEC-049-A §6 deliberately left **pilot-gated** behind two unanswered empirical
questions (Q2 export determinism, Q3 independent-checker wall-clock),

**facing** the fact that these questions cannot be settled by reasoning — only by
running `lean4export` + an independent checker on real unsorry closures and
measuring — and that committing to a Phase-3 rebuild *before* the data would risk
the documented ">100× slower" definitional-equality pathology and the cross-machine
non-determinism failure mode,

**we decided for** running a **non-merge-gating, observe-only research pilot**
(SPEC-093-A): a driver exports a sample of library modules with `lean4export`
(pinned `v4.30.0`, matching the toolchain), hashes the exports, re-exports on a
second runner to measure **cross-machine determinism (Q2)**, and runs `nanoda`
against the exports under a timeout to measure **wall-clock + the `nanoda`/
`leanchecker` ratio and timeout-hit rate (Q3)** — emitting a **data report** that
feeds a *future* Phase-3 ADR. The pilot **gates nothing**, admits no content, and
leaves the authoritative gate (`leanchecker`-on-locally-rebuilt-environment)
**unchanged**,

**and neglected** (a) skipping straight to a Phase-3 rebuild without the data
(rejected — it would lean on unproven determinism / wall-clock assumptions ADR-049
explicitly flagged as open); (b) making the export re-check merge-gating now
(rejected — SPEC-049-A §4: any non-kernel signal is advisory until proven, and this
is unproven); (c) lowering the central re-check below `p = 1` (explicitly out of
scope — a separate ADR amending ADR-049, gated on this pilot's data); and (d)
TEE/hardware attestation (rejected by ADR-049),

**to achieve** the empirical evidence that decides whether Phase 3 (the only
throughput-slope-changer) is real, **before** any soundness-surface change is
designed — turning ADR-049's two open questions from speculation into measured fact,

**accepting that** the pilot spends some real compute on research that admits no
proofs; that a negative result (non-deterministic export, or an unbounded `nanoda`
wall-clock) is a *valid and valuable* outcome that keeps `leanchecker` authoritative
and redirects effort to Track A levers (e.g. the per-shard rebuild de-dup, #5751);
and that `nanoda` may not support the current export format, in which case **the
deliverable is to report that blocker**, not to force it.

## What ships in this ADR

| Ships (this ADR / SPEC-093-A) | Out of scope (separate decisions) |
|---|---|
| Decision to run an observe-only pilot answering Q2 + Q3 | A Phase-3 rebuild / making the export re-check merge-gating |
| A pilot driver (`tools/pilot/`) + a non-required `workflow_dispatch` workflow | Lowering central `p < 1` (amends ADR-049) |
| A data report (export determinism, `nanoda` wall-clock/ratio/timeout rate) | TEE/hardware attestation (rejected, ADR-049) |

## Consequences

- **Positive.** ADR-049's two Phase-3 open questions become measured fact; the
  slope-changer decision is de-risked before any soundness change is designed.
- **Positive.** Zero gate risk: observe-only, gates nothing, authoritative gate
  unchanged. A negative result is as useful as a positive one.
- **Negative.** Spends research compute that admits no proofs.
- **Negative.** `nanoda` export-format compatibility is unconfirmed; a blocker there
  reduces the deliverable to a documented blocker (still useful — it scopes Q3).

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | lean4export + nanoda pilot spec | Specification | specs/SPEC-093-A-Lean4export-Nanoda-Independent-Checker-Pilot.md |
| REF-2 | Decentralised CI Runner Architecture | Decision | ADR-049-Decentralised-CI-Runner-Architecture.md |
| REF-3 | Decentralised CI Runner — Tiered Split (Phase 3 open questions) | Specification | specs/SPEC-049-A-Decentralised-CI-Runner-Architecture.md |
| REF-4 | Sharded Gate A Axiom Audit (Track A, shipped) | Decision | ADR-091-Sharded-Gate-A-Axiom-Audit.md |
| REF-5 | Verification-throughput roadmap | Discussion | GitHub discussion #5656 |
| REF-6 | D2 — lean4export + nanoda pilot | Issue | GitHub issue #5684 (roadmap #5678) |
| REF-7 | lean4export | External | https://github.com/leanprover/lean4export |
| REF-8 | nanoda independent Lean checker | External | https://github.com/ammkrn/nanoda_lib |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-24 |
