# ADR-084: Demand-Driven Sourcing Dedup — Skip When a Sourcing PR Is In Flight

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-084 |
| **Initiative** | unsorry — decentralised swarm infrastructure (sourcing concurrency) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-22 |
| **Status** | Accepted |

## WH(Y) Decision Statement

**In the context of** demand-driven sourcing (`swarm/sourcing.sh --if-pool-empty`,
ADR-067) wired into the launcher as a default-on arm (ADR-069), where the swarm is
meant to be decentralised — any node running `run.sh` contributes proving,
dispatching, **and** sourcing — and the dispatcher already tolerates concurrency
safely via goal-level dedup (ADR-064/071) + first-merge-wins (ADR-004),

**facing** the fact that the `--if-pool-empty` gate keyed **only** on the open-goal
count (`open_goal_count`), and an in-flight `chore(sourcing)` PR is **not** counted
as backlog until it merges (the ADR-067/069 snapshot semantics they explicitly
recorded as an accepted negative) — so two concurrent sourcers, or even a single
sourcer on its next `UNSORRY_SOURCING_WAIT` tick before its prior PR merged, both
see an empty pool and both open a `chore(sourcing)` PR, over-sourcing the backlog
(duplicate/again-overlapping goal batches, wasted Claude + Gate A capacity, and PRs
that first-merge-wins then strands) — the sourcing analogue of the dispatch
duplication ADR-064/071 already closed,

**we decided for** giving the demand-driven gate the **same in-flight check the
dispatcher has**: when the pool is empty, also skip if an open `chore(sourcing)` PR
already exists ("replenishment in flight"). The decision is a pure
`sourcing_gate_decision(open_n, pr_open)` → `have-work | in-flight | source`
(hermetically self-tested), fed by a thin best-effort `sourcing_pr_in_flight` that
lists open PRs by title via the **core API** (not the rate-limited search API, per
ADR-064/071) and is consulted **only** on an empty pool (≤ one `gh` call per
empty-pool tick),

**and neglected** (a) an atomic cross-process sourcing lock / claim (a millisecond
TOCTOU remains between the check and the Claude session's `gh pr create`, deferred
exactly as ADR-071 deferred the dispatch lock — first-merge-wins keeps any residual
duplicate sound, just wasteful); (b) counting an in-flight sourcing PR's goals as
backlog in `open_goal_count` (couples the pool definition to PR state and to the
PR's eventual contents, which aren't known until the Claude session runs); and
(c) hardening the sourcer's shared-checkout contention, which is the separate
worktree-isolation follow-up (ADR-085),

**to achieve** a sourcing arm that is safe for the decentralised "anyone runs
`run.sh`" model — concurrent sourcers (and back-to-back ticks) converge on at most
one in-flight replenishment instead of piling on duplicates — closing the
over-sourcing race ADR-067/069 left open, with no change to manual `sourcing.sh`,

**accepting that** the check is best-effort (a `gh` failure degrades to "no PR in
flight" so sourcing is never blocked by API health, ADR-016 posture), that a
sub-second TOCTOU before `gh pr create` can still let two sourcers race a single
replenishment open (sound by first-merge-wins, just wasteful), and that the
in-flight PR is recognised by its `chore(sourcing)` title prefix (the existing,
enforced sourcing-PR convention).

## Consequences

- **Positive.** Demand-driven sourcing is concurrency-safe to the same standard as
  dispatch; the swarm can run many `run.sh` nodes without over-sourcing. Also fixes
  the single-node cross-tick over-source that ADR-067/069 accepted as a negative.
- **Negative.** A residual sub-second TOCTOU remains (sound, wasteful) until the
  deferred sourcing lock; the gate now pays one `gh pr list` per empty-pool tick.
- **Amends** ADR-067 / ADR-069 (adds the missing in-flight check to their gate);
  **mirrors** ADR-064 / ADR-071 (dispatch dedup) for sourcing.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Demand-driven sourcing dedup spec | Specification | specs/SPEC-084-A-Demand-Driven-Sourcing-Dedup.md |
| REF-2 | Demand-Driven Sourcing | Decision | ADR-067-Demand-Driven-Sourcing.md |
| REF-3 | Launcher Demand-Driven Sourcing Arm | Decision | ADR-069-Launcher-Demand-Driven-Sourcing-Arm.md |
| REF-4 | Goal-Level Dispatch Deduplication (the dispatch analogue) | Decision | ADR-064-Goal-Level-Dispatch-Deduplication.md |
| REF-5 | Fresh Pre-Create Dedup Re-check (concurrent-dispatcher safety) | Decision | ADR-071-Fresh-Dispatch-Dedup-Recheck.md |
| REF-6 | Sourcer worktree isolation (the concurrency follow-up) | Decision | ADR-085-Sourcer-Worktree-Isolation.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-22 |
| Accepted | unsorry maintainers | 2026-06-22 |
