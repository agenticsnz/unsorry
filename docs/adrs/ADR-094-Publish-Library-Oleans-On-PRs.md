# ADR-094: Publish Library Oleans on PRs (reliable per-shard env handoff)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-094 |
| **Initiative** | verification capacity / throughput (Track A fast-follow to ADR-091) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-24 |
| **Status** | Proposed |

## Context

ADR-063 (sharded replay) and ADR-091 (sharded audit, v1.33.0) fan Gate A's verify
work across N matrix shards. Each shard is meant to **reuse** the library oleans
`gate-a-prepare` already built — via the ADR-046 Namespace `.lake` volume, or, when
that misses, the ADR-045 GitHub fallback cache — so a shard's `lake build
UnsorryLibrary --wfail` is an incremental no-op, not a cold rebuild.

The Namespace `.lake` volume is **per-runner and not reliably shared** to downstream
jobs: `gate-a.yml` records a measured case (2026-06-22) where `prepare` mounted a
warm 20 GB volume but a downstream job got an empty 4 KB one and **cold-rebuilt the
whole library (~45 min, hit the timeout)**. The ADR-045 fallback cache exists for
exactly this — `prepare` saves `.lake/build` under
`lake-build-<os>-<hash(toolchain,manifest,lakefile)>-<sha>`, and each shard's
cold-volume fallback restores it (exact-`<sha>` key + a `lake-build-<os>-<hash>-`
prefix restore-key).

**The gap (issue #5751):** that publish step is gated `github.ref ==
'refs/heads/main'` — it **only publishes on `main` pushes, never on PRs**. So on a
PR a shard that misses its volume has **no exact-`<sha>` entry** from `prepare`; it
falls back to the prefix restore-key (the latest *main* oleans) and reconciles with
an incremental build — usually fast, but **cold-builds (~21–45 min) whenever that
prefix entry is missing or LRU-evicted** (e.g. just after a toolchain / manifest /
lakefile bump, or under cache churn). Sharding **amplifies** this: N shards = N
independent chances to hit a cold volume *and* a fallback miss. D1a's production
measurement (#5678) saw exactly this — a 1077 s (~18 min) shard tail against a
256 s median.

The publish was main-only deliberately, to **bound GitHub-cache entry count** (the
10 GB repo cache, LRU-evicted; ~320 MB/entry ⇒ ~30 entries). That budget concern is
real but operational, not a soundness or scoping property.

## WH(Y) Decision Statement

**In the context of** a sharded Gate A (ADR-063/091) whose shards depend on reusing
`gate-a-prepare`'s library oleans, where the Namespace `.lake` volume is per-runner
and not reliably shared, and the ADR-045 GitHub fallback cache — the safety net for
exactly that miss — **publishes only on `main`, leaving PR shards with no
exact-`<sha>` handoff** and a cold-rebuild tail (#5751, the 1077 s outlier in #5678),

**facing** the fact that the per-runner volume miss is intrinsic to the Namespace
substrate (ADR-046) and that sharding multiplies the exposure, while the existing
fallback cache already has the exact mechanism (key + restore) to fix it — it is
simply not populated on PRs,

**we decided for** **publishing `prepare`'s library oleans to the ADR-045 fallback
cache on PRs as well as `main`** (drop the `github.ref == 'refs/heads/main'` clause;
keep `active && prepare_volume`, and skip forks whose read-only token cannot write
the cache), keyed on the run's `<sha>` exactly as today — so every audit/replay
shard of that run gets an **exact-`<sha>` restore hit** and its `--wfail` build is an
incremental no-op, never a cold rebuild. The step stays **`continue-on-error`** and
**non-gating**, so it can only help or be neutral: when the save succeeds a shard
restores the exact oleans; when it fails or is evicted the shard falls back to the
prefix restore-key — **today's behaviour** — so the change is a strict superset that
**degrades gracefully**,

**and neglected** (a) an `actions/upload-artifact` / `download-artifact` handoff of
`prepare`'s `.lake/build` to the shards (rejected — the SPEC-049-A §2
no-artifact-into-the-gate invariant, enforced by the conformance suite, forbids any
artifact-download step in `gate-a.yml`; the `actions/cache` path is the sanctioned
trusted-CI handoff and is already wired); (b) a Namespace cross-runner / run-shared
volume (rejected for now — the substrate exposes only a per-runner volume, ADR-046;
out of scope); (c) keeping it main-only and just raising shard memory or timeouts
(rejected — treats the symptom, not the missing handoff); and (d) publishing under a
`run_id` key instead of `<sha>` (rejected — `<sha>` already matches the shards'
restore key verbatim, so no key change is needed),

**to achieve** elimination of the per-shard cold-rebuild tail and a cut in
**runner-minutes per PR** (an exact restore makes `--wfail` a no-op instead of an
incremental build) — the runner-minute cost that, unlike per-PR latency, actually
bounds steady-state throughput (#5656 Track A; the lever D1a did *not* move),

**accepting that** per-PR publishing roughly doubles the fallback-cache write rate,
so the 10 GB LRU cache churns faster — bounded because the entries a run needs (its
own `<sha>` and the latest `main` baseline) are always seconds-to-minutes old and so
never the eviction victims, and because a failed/evicted save degrades to today's
behaviour (never worse); that the gain is largest on the cold-build tail and the
toolchain-bump path, not necessarily the warm median; and that this is **validated
in production** by monitoring the audit-shard timing distribution (median *and*
tail) and cache-hit rate on new proof PRs after it lands, reverting if the median
regresses from cache thrash.

## Consequences

- **Positive.** PR shards get an exact-`<sha>` olean handoff → no cold rebuild; the
  1077 s tail (#5678) and the toolchain-bump cold path are removed; `--wfail` becomes
  a no-op (fewer runner-minutes/PR — the throughput-bounding cost).
- **Positive.** Strict superset of current behaviour; `continue-on-error` + fallback
  means it can only help or be neutral. No soundness change — `leanchecker` /
  `axiom_audit` re-check every restored olean, and Lake rebuilds any whose source
  changed (ADR-045 invariant unchanged).
- **Negative.** ~2× fallback-cache write rate ⇒ faster LRU churn of the 10 GB repo
  cache; mitigated (needed entries are always fresh) and reversible. Monitor for a
  warm-median regression.
- **Negative.** Extends a soundness-adjacent caching surface (ADR-045) under
  CODEOWNERS; the publish remains non-gating evidence, never a trusted input.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Persistent Library Build Cache for Gate A (extended here) | Decision | ADR-045-Gate-A-Library-Build-Cache.md |
| REF-2 | Gate A library build cache spec | Specification | specs/SPEC-045-A-Gate-A-Library-Build-Cache.md |
| REF-3 | Namespace `.lake` Cache Volume for Gate A | Decision | ADR-046-Gate-A-Namespace-Cache-Volume.md |
| REF-4 | Sharded Gate A Axiom Audit (D1a) | Decision | ADR-091-Sharded-Gate-A-Axiom-Audit.md |
| REF-5 | Sharded Gate A Kernel Replay | Decision | ADR-063-Sharded-Gate-A-Kernel-Replay.md |
| REF-6 | Decentralised CI Runner — no-artifact invariant | Specification | specs/SPEC-049-A-Decentralised-CI-Runner-Architecture.md |
| REF-7 | Per-shard cold rebuild (env handoff) | Issue | GitHub issue #5751 (roadmap #5678) |
| REF-8 | Gate A cold-start build cost won't scale | Issue | GitHub issue #1921 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-24 |
