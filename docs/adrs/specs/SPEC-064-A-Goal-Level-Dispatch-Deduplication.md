# SPEC-064-A: Goal-Level Dispatch Deduplication

Implements: [ADR-064](../ADR-064-Goal-Level-Dispatch-Deduplication.md) | Status: Accepted | Updated: 2026-06-17

This spec defines the dispatcher contract that bounds prove-PR creation to one
PR per goal, implemented in `swarm/agent.sh`.

## 1. Invariant

For any goal `g`, `--dispatch-queue` opens **at most one** prove PR per dispatch
pass, and never opens one when an open prove PR for `g` already exists or `g` is
already proved on `main`. Sibling `queued/prove/g/*` branches are left in place
(non-destructive); they are skipped, not deleted.

## 2. Goal extraction

For a remote-tracking ref `origin/queued/prove/<goal>/<agent>-<hex>`, the goal is
the path segment after `queued/prove/`:

```
branch="${ref#origin/}"          # queued/prove/<goal>/<agent>-<hex>
goal="${branch#queued/prove/}"   # <goal>/<agent>-<hex>
goal="${goal%%/*}"               # <goal>
```

## 3. Skip predicates (evaluated in order, per branch)

1. **Already handled this pass** — the goal is in the in-pass seen-set. Skip.
2. **Already proved on `main`** — `goal_already_proved` returns true. Skip and
   add the goal to the seen-set.
3. **Prove PR already exists** — the goal is in the upfront open-PR-goal set
   (`dispatch_open_pr_goals`, any sibling branch) **or** `queued_branch_has_pr
   <branch>` (this exact branch, any state — catches a closed/merged PR). Skip
   and add the goal to the seen-set.

A branch passing all three is eligible for dispatch, subject to the existing
`submission_governor_allows` gate and `UNSORRY_DISPATCH_LIMIT`. On successful
dispatch the goal is added to the seen-set; on dispatch *failure* it is not, so a
sibling may be attempted (and will itself be caught by predicate 3 if the failed
attempt nonetheless created a PR).

### Rate-limit constraint (why the open-PR check is collected upfront)

The open-PR membership in predicate 3 is resolved from a **single** list-API call
made once per pass (`dispatch_open_pr_goals`: `gh pr list --state open`, core
quota, 5000/h), not a per-branch `gh ... --search`. The GitHub **search API is
30 requests/min**; a per-branch search over a large queue exhausts that bucket
and stalls the whole pass on retry backoff (observed: ~9 min for a ~283-branch
queue at `UNSORRY_DISPATCH_LIMIT` ≥ 10). The set is built before the loop and
checked by string membership — O(1) API cost regardless of queue size. A `gh`
error yields an empty set; `queued_branch_has_pr` and the post-create PR state
still prevent a genuine double-open.

## 4. `goal_already_proved`

The `library/index/<sha>.aisp` entry is the authoritative proved marker
(ADR-018); its record carries `goal≜<goal>;`. The check reads from a
freshly-fetched `origin/main`, not the working tree, because the dispatch loop
runs without re-syncing its checkout:

```
goal_already_proved() {
  local goal="$1"
  git grep -qF "goal≜$goal;" origin/main -- library/index 2>/dev/null
}
```

`dispatch_queue` calls `fetch_main_ref` (`git fetch origin +main:refs/remotes/origin/main`)
once per pass before the loop. A fetch or grep error degrades to "not proved"
(the branch is dispatched) — dedup must never block on infra health, matching the
best-effort posture of `open_prove_pr_exists` (ADR-017).

## 5. Testability seams

- `queued_branch_refs` — emits the candidate branch refs; stubbable in tests.
- `fetch_main_ref` — fetches `origin/main`; stubbable in tests.
- `dispatch_open_pr_goals` — emits the open-PR goal set; stubbable in tests.
- `goal_already_proved`, `queued_branch_has_pr`, `submission_governor_allows`,
  `dispatch_queued_proof_branch` — all stubbable.

`test_dispatch_goal_dedup` exercises the invariant: given two queued branches for
goal `g1`, one for an already-proved goal `g2`, and one for `g3` that already has
an open prove PR (in the `dispatch_open_pr_goals` set), exactly one (a `g1`)
branch is dispatched.

## 6. Out of scope

- The prove-time claim race that produces the duplicate branches (ADR-064
  Option 2, deferred).
- Bulk deletion of existing redundant branches (separate operational cleanup).
- Cross-pass in-memory dedup beyond what the open-PR check provides.
