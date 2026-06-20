# ADR-064: Goal-Level Dispatch Deduplication

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-064 |
| **Initiative** | unsorry Phase 3 — verifier capacity efficiency |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** the ADR-058 coordinated-submission model, where a `--prove`
agent in `UNSORRY_SUBMIT_MODE=queue` pushes a locally-verified proof to a
`queued/prove/<goal>/<agent>-<hex>` branch and a separate `--dispatch-queue`
loop later opens those branches as PRs under the submission governor,
**facing** a queue that had grown to 653 branches covering only 316 distinct
goals — 337 branches (52%) were duplicate goals and a further 26 goals were
already proved on `main` — so over half the namespace verifier capacity needed
to drain the queue would be spent on proofs that can never merge (first-merge
wins, ADR-004) and instead close as conflicts, exactly the #1924/#1925 pair we
observed; the duplication itself is the claim-race window ADR-017 knowingly left
unfixed (`queued_prove_branch_exists` is a non-atomic pre-check, so N agents
selecting the same top-ranked goal in one window all pass it and push distinct,
non-colliding branch names) compounded by claim-TTL expiry reopening goals whose
proofs sit undispatched — but ADR-017's mitigation (the supervisor closing
duplicate *PRs*, keeping the oldest) never fires because queue-mode duplicates
are *branches*, not PRs,
**we decided for** moving the in-flight-work guard to the dispatch boundary: the
dispatcher opens **at most one prove PR per goal per pass**, skipping a queued
branch whose goal is already proved on `main` (authoritative `library/index`
marker read from freshly-fetched `origin/main`), already has an open prove PR
(`open_prove_pr_exists`), or was already handled earlier in the same pass (an
in-run seen-set) — non-destructively, so a goal's sibling branches survive as
fallbacks until one of them merges,
**and neglected** (a) fixing the prove-time claim race itself — making the queued
branch race-safe (a fixed per-goal branch name so the second push loses on
non-fast-forward, or holding the claim live until dispatch/merge) — kept deferred
exactly as ADR-017 deferred it, because dispatch-level dedup already bounds the
cost to "verified-once-locally, dispatched-once"; and (b) bulk-deleting the
existing redundant branches, left as a separate operational cleanup since the
dispatcher now simply never opens them,
**to achieve** a dispatcher whose useful throughput is the goal-merge rate, not
the branch count — recovering the ~56% of verifier capacity previously burned on
unmergeable duplicates with no new runners,
**accepting that** the proved-on-main and open-PR checks are best-effort (a git
or `gh` error degrades to "not deduped" and the branch is dispatched, matching
ADR-017's "selection must not depend on API health"), the in-run seen-set bounds
duplicates only within a single pass (cross-pass duplicates are caught by the
open-PR check once the first PR exists), and one extra `git fetch origin main`
runs per dispatch pass.

## Context

This ADR is the queue-era continuation of ADR-017. ADR-017 identified the
claim-race that produces duplicate proofs (#184/#185) and chose to bound its
*cost* via PR-level hygiene rather than fix the race. ADR-058 then changed where
duplicates land — from immediately-open PRs to dormant `queued/prove/*` branches
— which silently removed ADR-017's bound: the supervisor's duplicate-PR closer
operates on PRs, so branch-resident duplicates accumulated unchecked until the
dispatcher amplified them into PRs. ADR-064 restores the bound at the new
boundary (dispatch) instead of the old one (PR-open).

The change is confined to `swarm/agent.sh`'s `dispatch_queue`, reusing the
existing `open_prove_pr_exists` guard and adding a `goal_already_proved` check
plus a per-pass seen-set. Branch sourcing is factored into `queued_branch_refs`
and main-fetch into `fetch_main_ref` so the dedup is hermetically self-tested
(`test_dispatch_goal_dedup`).

## Options Considered

### Option 1: Dispatch-level one-PR-per-goal dedup (Selected)
**Pros:** smallest surgical change; reuses proven guards; non-destructive
(siblings remain as fallbacks); recovers ~56% capacity immediately; same
best-effort posture as ADR-017.
**Cons:** does not stop the wasted *prove* compute upstream (the duplicate
branches are still produced), only the wasted *verify* compute downstream.

### Option 2: Fix the prove-time claim race (Rejected for now)
Make queued-branch creation atomic per goal (fixed branch name, first-push-wins
like the claims branch) or hold the claim live until dispatch. **Pros:** stops
duplication at the source, saving prove compute too. **Cons:** larger change to
the claim lifecycle (ADR-004/ADR-010) with its own race and overwrite hazards;
deferred deliberately, as in ADR-017, because dispatch-level dedup already caps
the cost. Tracked as the follow-up this ADR explicitly leaves open.

### Option 3: Destructive sibling pruning at dispatch (Rejected)
Delete a goal's other queued branches once one is chosen. **Pros:** shrinks the
visible queue. **Cons:** loses the fallback if the chosen proof fails Gate A;
unnecessary, since a skipped branch is harmless and a separate GC can prune
already-merged goals' branches safely.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Amends | ADR-017 | Swarm Supervisor and In-Flight-Work Guard | Extends the in-flight guard from the PR-open boundary to the dispatch boundary |
| Amends | ADR-058 | Runner Pool Segmentation and Verification Capacity | Makes `--dispatch-queue` open one PR per goal |
| Depends On | ADR-018 | Byte-Identity / index proved marker | `library/index` is the authoritative proved check |
| Relates To | ADR-004 | Claims Branch — First-Push-Wins | The unfixed claim race is the upstream cause |
| Relates To | ADR-010 | Affinity-Gap Selection | `queued_prove_branch_exists` pre-check is the racy guard |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-064-A — Goal-level dispatch deduplication | Specification | specs/SPEC-064-A-Goal-Level-Dispatch-Deduplication.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
| Accepted | unsorry maintainers | 2026-06-17 |
