# ADR-091: Sharded Gate A Axiom Audit

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-091 |
| **Initiative** | verification capacity / throughput |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-24 |
| **Status** | Proposed |

## Context

Discussion #5656 (and the roadmap issue #5678 / #5682) records the current Gate A
throughput ceiling: a flat **~24 proof-merges/hour** with no headroom, where each
green PR costs ~10–12 namespace runner-minutes and the **axiom audit is ~55–65% of
that (~360–443 s)** — by far the largest single chunk, and grown ~2.5× from the
~165 s measured in SPEC-049-A §5.6 as the verified library scaled. The kernel
**replay** long pole was already cut by **ADR-063** (sharded across N matrix
runners, ~1/N wall-clock) and is now cheap; **the axiom audit is the remaining
unsharded straggler and the concurrency choke.**

The audit driver (`tools/gate_a/parallel_modules.py::audit`) already **chunks** the
work (`split_evenly`) and supports intra-process parallelism
(`ThreadPoolExecutor`, bounded by `max_safe_jobs`), and its scope is already
**incremental** (changed library closure + changed goals, `scoped_audit_targets`,
fail-closed via `forces_full_audit`). But the required `gate-a.yml` invokes it with
**`--jobs 1`**: each `axiom_audit` process loads the full mathlib image (~6–7 GB)
to run `collectAxioms`, so two concurrent invocations OOM a single runner — exactly
the per-runner memory constraint ADR-063 faced for `leanchecker`. That constraint
is *intra-runner*; it says nothing about auditing disjoint module subsets on
**separate** runners. SPEC-063-A §6 already names audit sharding as the documented
fast-follow ("same planner; even safer").

The load-bearing soundness invariant is unchanged (ADR-048/049): **every
in-scope module is axiom-audited against the whitelist `{propext,
Classical.choice, Quot.sound}` (∪ `sorryAx` for goals), from a locally-derived
trusted-CI build, never from a client artifact.** ADR-058 governs verification
capacity and requires a **non-required shadow pilot before any change to
required-check routing**.

## WH(Y) Decision Statement

**In the context of** a Gate A axiom audit that is already chunked, incrementally
scoped, and order-independent, yet pinned to `--jobs 1` on one runner only because
each `axiom_audit` process holds mathlib resident — making it the now-dominant
~55–65% of per-PR verifier cost and the binding constraint on the ~24-merges/hour
throughput ceiling (#5656/#5682),

**facing** the need to raise throughput without weakening the every-module-audited
invariant (ADR-048/049), without trusting any client-supplied artifact, and
without changing the required-check contract before it is piloted (ADR-058),

**we decided for** **sharding the axiom audit across N parallel matrix runners**,
mirroring ADR-063 verbatim for the audit lane: a new **`compute_audit_targets`**
(factored out of `audit` as the single source of truth, returning an `AuditScope`
of `{full | incremental | none}` over **both** library and goal modules, reusing
`scoped_audit_targets` / `forces_full_audit` unchanged) feeds a new
**`plan_audit_shards`** that emits an N-way matrix index list, and a new
**`audit_shard`** re-derives the **same** scope from source on each leg and audits
only `split_evenly(library ++ goals, N)[i]` — separating its slice back into the
plain (`axiom_audit`) and `--allow-sorry` (goal) invocations — so each leg shares
nothing but the git SHA (no module list crosses a job boundary, keeping the
auditor's inputs locally-derived). Because `split_evenly` is **disjoint and
covering** (unit-tested) and the per-module audit verdict is independent, all
shards green ⟺ every module audited exactly once, at ~1/N wall-clock; a
**`combine_audit_reports`** concatenates the per-shard `axiom-report.json`
fragments into the unified footprint report. Gated by a **cover job** (`fail-fast:
false` matrix + a cover that fails closed unless every shard is green, or `count ==
0` vacuously) and the unchanged **daily full-audit backstop**; rolled out
**non-required first** via an audit leg in the existing `gate-a-shard-pilot`
workflow before promotion into the required `gate-a.yml` (ADR-058),

**and neglected** lifting the per-runner `--jobs` cap to run two audits on one fat
runner (rejected as the primary fix — bounded by one runner's RAM and OOM-prone,
the same reason `--jobs 1` exists today; cross-**runner** sharding is the
unbounded, memory-safe parallelism, though a fat-profile shard may still use
intra-runner jobs later), passing a precomputed shard plan between jobs as an
artifact (rejected — re-deriving the slice on each leg from the shared SHA keeps
the auditor's inputs locally-derived and sidesteps the ADR-049 client-artifact
footgun), promoting the matrix straight into the required gate (rejected — ADR-058
mandates a non-required pilot first, and the empty-matrix/skip and matrix-expansion
behaviours need real-runner validation), and simply buying bigger/more runners (an
operator capacity lever, orthogonal to per-run wall-clock and not a repo change),

**to achieve** an ~N× cut in the now-dominant audit cost so Gate A throughput
scales with the operator's runner budget instead of one serial audit, lifting the
~24-merges/hour ceiling (#5656),

**accepting that** sharding introduces a *bookkeeping* risk identical in kind to
the existing ADR-048 incremental-scoping risk — a planner bug that drops a module
would let it reach `main` un-audited — bounded three ways: the partition is
unit-tested disjoint+covering, the cover job fails closed on any non-green shard,
and the daily full-audit backstop re-derives soundness within 24 h and goes red on
any gap; that the required-gate promotion is a separate, pilot-gated step (the
pilot leg ships first); that the shard count N is a new operator capacity knob
(`vars.UNSORRY_AUDIT_SHARDS`, separate from `UNSORRY_REPLAY_SHARDS`) spending N
parallel verifier runners (ADR-058 governance), so peak concurrent runners per PR ≈
replay + audit shard counts; and that the audit cover job becomes
soundness-load-bearing and joins the CODEOWNERS TCB (ADR-019).

## What ships in this ADR (vs the follow-up)

| Ships now (this ADR / SPEC-091-A) | Deferred |
|---|---|
| `compute_audit_targets` + `plan_audit_shards` + `audit_shard` + `combine_audit_reports` (reuse the verbatim scoping logic) | Intra-runner `--jobs > 1` on a fat audit-shard profile |
| Unit tests: disjoint+covering partition (library ∪ goals), fail-closed-to-full, no-op empty matrix, out-of-range no-op, failure propagation, composable-fragment | Sharding the daily `gate-a-full-replay`/full-audit backstop |
| Audit leg in `gate-a-shard-pilot` — non-required manual validation on real runners | — |
| Promotion of the audit matrix into the **required** `gate-a.yml` (after the pilot is green) | — |

The serial `audit()` (`--jobs 1`) path is **unchanged** and remains the
fallback/backstop.

## Consequences

- **Positive.** The now-dominant audit cost drops to ~1/N wall-clock; Gate A
  throughput scales with the runner budget. With replay (ADR-063) and audit both
  sharded, the per-PR critical path is bounded by the slower of the two matrices,
  not a serial sum.
- **Positive.** No soundness weakening: scope logic reused verbatim, shards share
  only the SHA, coverage is unit-proven and cover-job-enforced, the daily full
  backstop is unchanged.
- **Positive.** Zero risk to the required gate until promotion — the pilot leg is
  non-required and manual.
- **Negative.** A new bookkeeping surface (the partition) carries a latent,
  backstop-caught under-scoping risk; the audit cover job is now
  soundness-load-bearing and must stay in the CODEOWNERS TCB (ADR-019).
- **Negative.** N parallel runners per audit is real capacity spend (ADR-058); N
  must be tuned to Namespace concurrency alongside the replay shard count.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Sharded Gate A axiom audit spec | Specification | specs/SPEC-091-A-Sharded-Gate-A-Axiom-Audit.md |
| REF-2 | Sharded Gate A Kernel Replay | Decision | ADR-063-Sharded-Gate-A-Kernel-Replay.md |
| REF-3 | Runner-Pool Segmentation and Verification Capacity | Decision | ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-4 | Verify-on-Ingest | Decision | ADR-048-Verify-On-Ingest.md |
| REF-5 | Incremental Kernel Replay | Decision | ADR-033-Incremental-Kernel-Replay.md |
| REF-6 | Decentralised CI Runner Architecture | Decision | ADR-049-Decentralised-CI-Runner-Architecture.md |
| REF-7 | Gate A Workflow | Specification | specs/SPEC-006-B-Gate-A-Workflow.md |
| REF-8 | Verification-throughput roadmap | Discussion | GitHub discussion #5656 |
| REF-9 | D1a — shard the axiom audit | Issue | GitHub issue #5682 (roadmap #5678) |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-24 |
