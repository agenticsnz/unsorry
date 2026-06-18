# ADR-063: Sharded Gate A Kernel Replay

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-063 |
| **Initiative** | verification capacity / throughput |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Proposed |

## Context

Issue #1909 documents a verification-capacity bottleneck: under a flood of proof
submissions the queue grows faster than Gate A drains it, because each full Gate A
**kernel replay** (`gate-a-replay`, `leanchecker`) is a ~1-hour serial pass over
the whole active library (~289 modules), and the ADR-058 submission governor keeps
only ~20 PRs in flight — so steady-state throughput is capped at ~20 proofs/hour
and `gate-a-replay`/`gate-a-audit` runs sit queued for hours.

Routine proof PRs are already fast: ADR-033/048 made the per-PR replay
**incremental** (changed modules + their reverse-import closure), so a typical
proof finishes in seconds. The long pole is the **full-replay path** — an
olean-invalidating change (toolchain/lakefile/manifest bump), the zero-base
backstop, and the daily `gate-a-full-replay` — where every module is replayed.

The replay driver (`tools/gate_a/parallel_modules.py`) already **chunks** the
work (`split_evenly`, bounded by `UNSORRY_REPLAY_CHUNK`) and runs the chunks
**serially** with `effective_jobs = 1`. The serialization is not a soundness
requirement — it is a *per-runner memory* constraint: `leanchecker` holds ~all of
mathlib resident per process, so two concurrent invocations OOM-kill a single
runner (exit 143). That constraint is intra-runner; it says nothing about running
disjoint subsets on **separate** runners.

The load-bearing soundness invariant (ADR-048 §Soundness, ADR-049 §Soundness
item 3–4) is: **every changed olean is kernel-replayed exactly once, under its
pinned toolchain, from a locally-derived (trusted-CI) build — never from a client
artifact** — and the changed-module + reverse-import closure must be in scope.
ADR-058 governs verification capacity as an operator-controlled property and
requires a **non-required shadow pilot before any change to required-check
routing**.

## WH(Y) Decision Statement

**In the context of** a Gate A kernel replay that is already chunked but run
serially on one runner only because `leanchecker`'s mathlib-resident memory cost
forbids two concurrent invocations *per runner* — making the full-replay path a
~1-hour serial long pole that caps verification throughput (#1909),

**facing** the need to raise throughput without weakening the every-olean-
replayed-once invariant (ADR-048/049), without trusting any client-supplied
artifact, and without changing the required-check contract before it is piloted
(ADR-058),

**we decided for** **sharding the kernel replay across N parallel matrix
runners** (ADR-063): a new `plan` subcommand computes the replay target set
(reusing `compute_replay_targets` → `scoped_targets`/`replay_scope` verbatim, so
a shard's scope can never differ from a full replay's) and emits an N-way index
list for a GitHub `matrix`; a new `replay-shard` subcommand re-derives the **same**
target set from source on each leg and replays only `split_evenly(targets, N)[i]`
— so each leg shares nothing but the git SHA (no module list crosses a job
boundary, keeping `leanchecker`'s inputs locally-derived), and because
`split_evenly` is **disjoint and covering** (unit-tested), all shards green ⟺
every olean replayed exactly once, at ~1/N the wall-clock; gated by a **coverage
guarantee** (the partition is proven disjoint+covering in unit tests, and the
matrix runs `fail-fast: false` with a cover job that fails closed unless every
shard is green) and the unchanged **daily full-replay backstop**; rolled out
**non-required first** via a manual `gate-a-shard-pilot` workflow that runs the
sharded matrix on real runners, with promotion into the required `gate-a.yml`
deferred until the pilot is green (ADR-058),

**and neglected** lifting the per-runner `effective_jobs` cap to run two
leancheckers on one fat runner (rejected as the primary fix — bounded by one
runner's RAM and explicitly OOM-prone per the existing code comment; sharding
across runners is the unbounded, memory-safe parallelism, though a fat-profile
shard may still use intra-runner jobs later), passing a precomputed shard plan
between jobs as an artifact (rejected — re-deriving the slice on each leg from the
shared SHA keeps `leanchecker`'s inputs locally-derived and sidesteps the ADR-049
client-artifact footgun entirely), promoting the matrix straight into the required
gate (rejected — ADR-058 mandates a non-required pilot before required-check
routing, and the empty-matrix/skip and matrix-expansion behaviours need real-
runner validation), and simply buying bigger/more runners (an operator capacity
lever that helps but is orthogonal to the per-run wall-clock and not a repo
change),

**to achieve** an ~N× cut in the full-replay long pole so Gate A keeps pace with
the submission rate (#1909), bounded only by the operator's chosen shard count
and Namespace concurrency,

**accepting that** sharding introduces a *bookkeeping* risk identical in kind to
the existing ADR-048 incremental-scoping risk — a planner bug that drops a module
would let an olean reach `main` un-replayed — bounded three ways: the partition is
unit-tested disjoint+covering, the cover job fails closed on any non-green shard,
and the daily `gate-a-full-replay` backstop re-derives soundness within 24h and
goes red on any gap; that the required-gate promotion is a separate, pilot-gated
follow-up (this ADR ships the tooling + the pilot, not the required-gate cutover);
that the shard count N is a new operator capacity knob that spends N parallel
verifier runners (ADR-058 governance); and that this first cut shards **replay**
only — `gate-a-audit` (already `--jobs`-parallel and order-independent) is a
documented fast-follow via the same planner.

## What ships in this ADR (vs the follow-up)

| Ships now (this ADR / SPEC-063-A) | Deferred (pilot-gated follow-up) |
|---|---|
| `plan` + `replay-shard` subcommands (reuse the verbatim scoping logic) | Promotion of the matrix into the **required** `gate-a.yml` replay job |
| Unit tests: disjoint+covering partition, fail-closed-to-full, no-op empty matrix, out-of-range no-op, failure propagation | Sharding `gate-a-audit` (same planner; even safer) |
| `gate-a-shard-pilot` — non-required manual workflow validating the matrix on real runners | Optional intra-runner `--jobs > 1` on a fat shard profile |

## Consequences

- **Positive.** The full-replay long pole drops to ~1/N wall-clock; Gate A
  throughput scales with the operator's runner budget instead of one serial hour.
- **Positive.** No soundness weakening: the scope logic is reused verbatim, shards
  share only the SHA, coverage is unit-proven and cover-job-enforced, and the
  daily full backstop is unchanged.
- **Positive.** Zero risk to the required gate until promotion — the pilot is
  non-required and manual.
- **Negative.** A new bookkeeping surface (the partition) carries a latent,
  backstop-caught under-scoping risk; the cover job and backstop are now
  soundness-load-bearing and must stay in the CODEOWNERS TCB (ADR-019).
- **Negative.** N parallel runners per full replay is real capacity spend
  (ADR-058); N must be tuned to Namespace concurrency.
- **Negative.** The throughput win lands only on promotion (a pilot-gated
  follow-up), not the moment this merges.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Sharded Gate A kernel replay spec | Specification | specs/SPEC-063-A-Sharded-Gate-A-Kernel-Replay.md |
| REF-2 | Runner-Pool Segmentation and Verification Capacity | Decision | ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-3 | Verify-on-Ingest | Decision | ADR-048-Verify-On-Ingest.md |
| REF-4 | Incremental Kernel Replay | Decision | ADR-033-Incremental-Kernel-Replay.md |
| REF-5 | Decentralised CI Runner Architecture | Decision | ADR-049-Decentralised-CI-Runner-Architecture.md |
| REF-6 | Gate A Workflow | Specification | specs/SPEC-006-B-Gate-A-Workflow.md |
| REF-7 | Gate A capacity bottleneck | Issue | GitHub issue #1909 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
