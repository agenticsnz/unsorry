# SPEC-109-A: contention-aware prove-PR quota + un-strand

Implements: [ADR-109](../ADR-109-Contention-Aware-Prove-PR-Quota.md) · amends
[ADR-054] · Status: Draft · Updated: 2026-06-29

Contract for the two halves of the ADR-109 fix. Pure logic in `tools/repo/pr_admission.py`
(`fair_share_cap`) and `swarm/agent.sh` (`_blocking_pr_count`), both unit/self-tested.

## 1. Contention-aware cap — `tools/repo/pr_admission.py`

- `fair_share_cap(budget: int, active_authors: int, floor: int = 1) -> int`:
  - `active_authors <= 1` → `max(budget, floor)` (sole contributor gets the whole budget).
  - else → `max(budget // active_authors, floor)`.
- CLI `quota` gains `--budget` and `--active-authors`. When **both > 0**, the effective cap is
  `fair_share_cap(budget, active_authors)`, overriding `--cap`; otherwise the flat `--cap` path is
  unchanged (back-compat). `quota_decide(open_count, cap)` is unchanged (inclusive: `<= cap` admits).
- `.github/workflows/pr-admission.yml` quota step: `BUDGET = vars.UNSORRY_MAX_OPEN_PROVE_PRS || 40`
  (the SAME budget the dispatcher's submission governor meters). From one `gh pr list --state open`
  it computes `count` = this author's open `queued/prove/*` PRs and `active` = distinct authors of
  open `queued/prove/*` PRs including the current one, then calls
  `quota --open-count count --budget BUDGET --active-authors active`.

## 2. Un-strand quota-closed branches — `swarm/agent.sh`

- `_blocking_pr_count(json, backoff)` (pure; real `jq`): counts PRs that block re-dispatch =
  `state == OPEN` ∨ `state == MERGED` ∨ (`state == CLOSED` ∧ (not labelled `over-author-quota` ∨
  `closedAt` within `backoff` seconds of now)).
- `queued_branch_has_pr(branch)`: fetch `gh pr list --state all --head <branch> --json
  state,labels,closedAt`; blocking iff `_blocking_pr_count(json, backoff) > 0`.
  `backoff = UNSORRY_QUOTA_RETRY_BACKOFF_S` (default 3600; non-integer → 3600). Any gh/empty/parse
  failure → `return 1` (no blocking PR → proceeds to dispatch; fail-open, unchanged, and the later
  `goal_taken_fresh` recheck still guards duplicates).
- Net: a branch whose ONLY PR(s) were quota-closed past the back-off is retryable; OPEN/MERGED and
  non-quota closes still strand-protect as before.

## 3. Churn-safety (must hold)

- Sole contributor: cap == budget == governor limit ⇒ no PR is quota-closed ⇒ nothing to retry ⇒ no
  open/close churn; previously-stranded branches re-dispatch and drain.
- Contention: each author bounded to `budget // N`; the back-off bounds re-dispatch of an
  over-share branch to once per `backoff`.

## 4. Tests

- `tools/repo/tests/test_pr_admission.py`: `fair_share_cap` (sole→budget, split, floor) and the CLI
  (contention-aware admit/reject, flat-cap back-compat).
- `swarm/agent.sh --self-test::test_queued_branch_has_pr_quota_retryable`: quota-closed past
  back-off retryable; non-quota close / open / merged / within-back-off block; empty list free.

## 5. Out of scope

No change to `quota_decide` semantics, the governor caps, ADR-106 ordering, the phantom
`stale-branch-janitor`, or soundness (admission is leaderboard/queue plumbing, never proof
admission).
