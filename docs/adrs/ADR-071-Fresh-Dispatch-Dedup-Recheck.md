# ADR-071: Fresh Pre-Create Dedup Re-check at Dispatch

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-071 |
| **Initiative** | unsorry Phase 3 — verifier capacity efficiency |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-18 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** ADR-064's goal-level dispatch dedup, where `dispatch_queue`
fetches `origin/main` and lists open prove PRs **once at pass start** and then
opens up to `UNSORRY_DISPATCH_LIMIT` PRs from the queued branches,
**facing** duplicate "already proved on main" PRs that kept re-appearing **after**
ADR-064 shipped (every closed duplicate — #2059, #2081, #2123, #2131, #2150,
#2164, #2174, #2179 … — was created after #1952 merged), because the pass-start
snapshot goes **stale during the pass**: a sibling proof of the same goal can
MERGE, or a concurrent dispatcher can OPEN a PR, between the pass-start checks and
the actual `gh pr create` — so the branch is dispatched into a dead duplicate
that first-merge-wins then strands as un-mergeable,
**we decided for** a **final fresh re-check immediately before each create**:
`goal_taken_fresh` re-fetches `origin/main` and re-lists open prove PRs, and
`dispatch_queue` skips the branch if the goal is now proved or already has an open
PR — run only for the handful actually being dispatched (after the governor
gate), using a `git grep` + one core-API list (never the 30/min search API,
ADR-064),
**and neglected** a fully atomic cross-process dispatch lock (a millisecond
TOCTOU remains between the fresh check and `gh pr create`; deferred — the window
shrinks from minutes-per-pass to milliseconds, and first-merge-wins keeps any
residual duplicate sound, just wasteful), and fixing the upstream prove-time
race that produces sibling branches in the first place (still the deeper
ADR-064 follow-up; this closes the dispatch-side leak that actually produced the
observed dead PRs),
**to achieve** a dispatcher whose "one PR per goal" holds across the duration of
a pass and against concurrent dispatchers, ending the recurring sweep of
already-proved duplicates,
**accepting that** each actual dispatch now costs one extra `git fetch origin
main` + one `gh pr list` (bounded by the dispatch limit, core quota), and the
check is best-effort — any git/gh error degrades to "not taken" so dispatch is
never blocked by infra health.

## Context

Amends ADR-064. ADR-064 stopped *same-pass* and *pass-start-known* duplicates;
this ADR closes the *stale-snapshot* window that let post-064 duplicates through.
The change is confined to `swarm/agent.sh` `dispatch_queue` plus the
`goal_taken_fresh` helper, and is hermetically self-tested
(`test_dispatch_skips_taken_midpass`).

## Options Considered

### Option 1: Fresh pre-create re-check (Selected)
**Pros:** directly kills the observed leak; tiny, contained; reuses ADR-064
helpers; affordable (per-dispatch, not per-branch); no search API.
**Cons:** a millisecond TOCTOU remains before `gh pr create`.

### Option 2: Atomic cross-process dispatch lock (Rejected for now)
A git-ref / lease lock so only one dispatcher acts on a goal at a time. Fully
closes the TOCTOU but adds a lock lifecycle and failure modes; deferred since
the fresh re-check reduces the window to negligible and first-merge-wins keeps
residual duplicates sound.

### Option 3: Fix the upstream prove-time race (Rejected as scope)
Stop sibling branches forming at claim time. The deeper ADR-064 follow-up;
larger claim-protocol change. This ADR fixes the dispatch-side leak that
produced the actual dead PRs; the prove-time race remains tracked.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Amends | ADR-064 | Goal-Level Dispatch Deduplication | Adds the fresh pre-create re-check ADR-064's pass-start snapshot misses |
| Depends On | ADR-018 | index proved marker | `goal_already_proved` reads `library/index` |
| Relates To | ADR-058 | Runner Pool Segmentation and Verification Capacity | Dispatcher is the consumer |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-071-A — Fresh pre-create dedup re-check | Specification | specs/SPEC-071-A-Fresh-Dispatch-Dedup-Recheck.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-18 |
| Accepted | unsorry maintainers | 2026-06-18 |
