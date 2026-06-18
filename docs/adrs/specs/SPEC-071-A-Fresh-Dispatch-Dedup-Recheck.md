# SPEC-071-A: Fresh Pre-Create Dedup Re-check at Dispatch

Implements: [ADR-071](../ADR-071-Fresh-Dispatch-Dedup-Recheck.md) | Status: Accepted | Updated: 2026-06-18

Amends SPEC-064-A. Adds a fresh re-check immediately before the dispatcher opens
a PR, in `swarm/agent.sh`.

## 1. Problem

ADR-064 evaluates its dedup predicates from a snapshot taken once at pass start
(`fetch_main_ref` + `dispatch_open_pr_goals`). Across a pass — and in the gap
before `gh pr create` — that snapshot goes stale: a sibling proof of the goal can
merge, or a concurrent dispatcher can open a PR. The branch is then dispatched
into a dead "already proved" duplicate. All observed post-ADR-064 duplicates were
of this class.

## 2. `goal_taken_fresh`

```
goal_taken_fresh() {
  local goal="$1"
  fetch_main_ref || true                          # refresh origin/main
  goal_already_proved "$goal" && return 0         # merged since pass start?
  dispatch_open_pr_goals | grep -qxF "$goal"      # PR opened since pass start?
}
```

Returns 0 (taken → skip) if the goal is now proved on `origin/main` **or** now
has an open prove PR. Uses `git grep` + one core-API `gh pr list` — never the
30/min search API. Any git/gh failure degrades to "not taken" (return non-zero),
so dispatch is never blocked by infra health.

## 3. Placement in `dispatch_queue`

The check runs **after** the governor gate and **immediately before**
`dispatch_queued_proof_branch`, so it only costs a fetch + list for the handful
of branches actually being dispatched (bounded by `UNSORRY_DISPATCH_LIMIT`), not
for every queued branch:

```
if ! submission_governor_allows; then ... fi
if goal_taken_fresh "$goal"; then           # ADR-071
  log "... goal $goal was taken during this pass (merged or already PR'd)"
  seen_goals="$seen_goals$goal "
  continue
fi
if dispatch_queued_proof_branch "$branch"; then ...
```

A skipped goal is added to the in-pass seen-set so its sibling branches are
skipped too.

## 4. Residual window

A millisecond TOCTOU remains between `goal_taken_fresh` and `gh pr create`
(no cross-process lock). First-merge-wins (ADR-004) keeps any residual duplicate
**sound** — it cannot merge twice — only wasteful. A fully atomic dispatch lock
and the upstream prove-time race fix are deferred (ADR-071 Options 2 & 3).

## 5. Test

`test_dispatch_skips_taken_midpass`: a goal that passes the pass-start checks but
for which `goal_taken_fresh` returns true is **not** dispatched (0 PRs opened).
`test_dispatch_goal_dedup` continues to pass (fresh check is transparent when the
goal is genuinely free).
