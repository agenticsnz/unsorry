# ADR-117: GitHub-Hosted Gate A Runners (Namespace Trial Ended)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-117 |
| **Initiative** | unsorry CI substrate — Gate A availability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-07-28 |
| **Status** | Accepted |

## Context

Every Gate A lane routes to the single Namespace label `namespace-profile-unsorry-1`
(ADR-058 consolidated three lanes into one for exactly this failure mode). The
namespace.so trial has ended, so **zero runners carry that label** and every
Lean-touching job queues forever — the hazard ADR-058's own comment names: *"a stage
with no runner queues forever … and stalls every merge."*

Observed: `repos/agenticsnz/unsorry/actions/runners` reports `total_count: 0`, and
PR #7160 (the first proof PR since the lapse) sat with `gate-a-prepare` and
`gate-a-benchmark` queued indefinitely while every other check passed. Merges that
touch no Lean still worked, because `detect`'s `lean` path filter skips the heavy
jobs — which is why the harness fixes in #7156 and #7158 merged normally and masked
the outage until the first proof arrived.

The repository is **public**, so GitHub-hosted standard runners are free and
unlimited. ADR-046 already anticipated this substitution: the `.lake` cache volume
engages *only* on a `namespace-*` label, and any other label sets `*_volume=false`,
which in turn enables the ADR-045 `actions/cache` path (`if: …_volume != 'true'`).
The failsafe needs no new code — only a label change.

Cost on GitHub-hosted hardware is bounded by `detect`'s existing path filters, not by
the runner. The expensive step, `lake build UnsorryLibrary --wfail` over the whole
repo library, is gated on the `active` filter (`library/**`, `goals/**/*.lean`,
`lakefile.toml`, `lake-manifest.json`, `lean-toolchain`, `AxiomAudit/**`,
`AuditFixtures/**`, `tools/gate_a/**`, `.github/workflows/gate-a.yml`). A benchmark
proof PR touches none of them — it changes `targets/<suite>/_verify/**`, a `.aisp`
goal record and a `proof-runs/` record — so `active` is false and only
`gate-a-benchmark` does real work: a suite `lake exe cache get` plus a small
suite-library build. The cold 794-module path engages only for PRs that touch the
repo library, and those face the existing 45-minute `gate-a-prepare` cap on 4 vCPU.

## WH(Y) Decision Statement

**In the context of** a Gate A whose every lane targets one Namespace runner label
(ADR-058) with the `.lake` cache volume bound to that substrate (ADR-046),
**facing** the end of the namespace.so trial leaving zero runners on
`namespace-profile-unsorry-1`, so every Lean-touching job queues forever and no proof
can merge — while non-Lean PRs still pass and hide the outage,
**we decided for** routing all four Gate A profiles to **`ubuntu-latest`**, relying on
ADR-046's existing non-`namespace-*` failsafe to switch the build cache from the
Namespace volume to the ADR-045 `actions/cache` path with no further code change,
**and neglected** re-subscribing to Namespace (restores the status quo but blocks
every merge until it is paid for and does not remove the single-vendor dependency),
registering a self-hosted runner under the existing label (free and needs no workflow
change, but merges then depend on one machine staying online, and a 15 GB box cannot
hold the parallel mathlib closures a cold library build maps), and disabling the Lean
gates to unblock merges (destroys the soundness bar Gate A exists to enforce),
**to achieve** a Gate A that runs on free, always-available, vendor-neutral capacity
so proofs merge again, with the cache path degrading automatically rather than
silently losing incrementality,
**accepting that** a PR touching `library/**` or `goals/**/*.lean` with a cold
`actions/cache` faces a full cold library build against the existing 45-minute
`gate-a-prepare` cap on 4 vCPU — slower than the Namespace lane and possibly requiring
a cap increase or a seeded cache — and that the three scheduled workflows still
pinned to the Namespace label (`gate-a-full-replay`, `independent-check-backstop`,
`lake-volume-janitor`) will accumulate queued runs until dispositioned separately;
none of them gates a merge, and `lake-volume-janitor` is meaningless without the
volume it maintains.

## Options Considered

### Option 1: Route Gate A to `ubuntu-latest` (Selected)
Change the four labels in `gate-a.yml`'s `profiles` step. **Pros:** free and unlimited
on a public repo; no vendor dependency; ADR-046's failsafe already routes the cache
correctly; benchmark PRs — this repo's dominant Lean PR shape — skip the expensive
build entirely via the `active` filter. **Cons:** cold repo-library builds are slower
on 4 vCPU and may crowd the 45-minute prepare cap.

### Option 2: Restore the Namespace subscription (Rejected)
Re-subscribe so the existing label has runners. **Rejected:** costs money, blocks every
merge until it is in place, and leaves Gate A availability hostage to one vendor —
the failure this ADR exists to answer.

### Option 3: Self-hosted runner under the existing label (Rejected)
Register a machine as `namespace-profile-unsorry-1`. **Rejected:** merges then depend on
one machine's uptime, and the observed 15 GB development box cannot build the repo
library — ten parallel Lean processes each map ~42k VMAs of the full mathlib closure
and exhaust memory, surfacing misleadingly as `Too many open files`.

### Option 4: Disable the Lean gates (Rejected)
Skip the heavy jobs so PRs merge. **Rejected:** Gate A soundness is the project's whole
premise; unverified proofs on `main` are worse than no merges.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Supersedes (substrate only) | ADR-058 | Gate A Lane Consolidation | The single-lane routing stands; its target label changes |
| Relies On | ADR-046 | Gate A Namespace Cache Volume | Its non-`namespace-*` failsafe is what makes this a label-only change |
| Relies On | ADR-045 | Gate A Library Build Cache | The `actions/cache` path this failsafe re-enables |
| Relates To | ADR-099 | Suite-Pin Benchmark Verification | `gate-a-benchmark` is the leg this unblocks first |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | GitHub-hosted Gate A runners spec | Specification | specs/SPEC-117-A-GitHub-Hosted-Gate-A-Runners.md |
| REF-2 | First suite-pin proof PR, stalled on the lapsed lane | PR | <https://github.com/agenticsnz/unsorry/pull/7160> |
| REF-3 | Suite-aware decomposition pilot | Issue | <https://github.com/agenticsnz/unsorry/issues/7151> |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-07-28 |
