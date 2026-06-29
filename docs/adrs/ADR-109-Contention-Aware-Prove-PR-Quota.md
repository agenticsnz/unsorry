# ADR-109: Contention-aware prove-PR quota + un-strand quota-closed branches (amends ADR-054)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-109 |
| **Initiative** | throughput / dispatch fairness (amends ADR-054) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-29 |
| **Status** | Proposed |

## Context

A live probe (2026-06-29) of why one contributor's queue (`@ohdearquant`, ~117 `gself-pow-*`
`template-ring-cofactor` proofs) had stopped draining for days found a **deadlock between two
fairness mechanisms**, with *no other contributor waiting* and the gate sitting idle:

1. **The ADR-054 per-author quota is a flat absolute cap of 20 open prove PRs**
   (`pr_admission.py quota`, `UNSORRY_MAX_OPEN_PROVE_PRS_PER_AUTHOR=20`), **contention-blind** — it
   counts only that author's own open PRs against a fixed 20 and never checks whether anyone else is
   competing.
2. **The dispatcher's submission governor opens up to `UNSORRY_MAX_OPEN_PROVE_PRS` = 40 total** open
   prove PRs (`agent.sh::submission_governor_reason`).

So for a **sole contributor**, the governor keeps opening PRs up to 40 while the quota closes every
one past 20 (labelling them `over-author-quota`). The per-author cap is *half* the budget it is
metering against — a single contributor is throttled to half the gate for no fairness benefit
(there is no one to be fair to).

That alone would only bound concurrency, except for the second half of the deadlock:

3. **The dispatcher's `queued_branch_has_pr` guard treated ANY prior PR — including a quota-closed
   one — as "already exists" (`gh pr list --state all`) and never re-dispatched the branch.** So the
   quota's own promise ("the goal returns to the pool; the producer will re-queue automatically") is
   **false** for a branch already produced: it is stranded permanently. As the 20 open PRs merged,
   the remaining queued branches all carried an `over-author-quota` close → the dispatcher opened
   nothing new → the queue froze at 0 open PRs with ~117 genuinely-unproved goals stuck.

(The complementary phantom case — branches whose goal is already proved — is already auto-reaped by
the hourly `stale-branch-janitor`; this ADR does not touch it.)

## Decision

**1. Make the per-author quota contention-aware (fair share = budget ÷ active contributors).**
The effective per-author cap becomes `UNSORRY_MAX_OPEN_PROVE_PRS` (the *same* budget the submission
governor meters, default 40) divided by the number of contributors with open `queued/prove/*` PRs
right now (`pr_admission.fair_share_cap`):

- a **lone contributor gets the whole budget** (cap == budget == governor limit → no spurious
  quota closes, no strand, no churn);
- **N contributors get an equal `budget // N`** (ADR-054 max-min fairness preserved under real
  contention);
- never below a floor of 1. The `pr-admission.yml` quota step computes the active-contributor count
  and passes `--budget`/`--active-authors`.

**2. Un-strand quota-closed branches in the dispatcher.** `queued_branch_has_pr` no longer treats a
PR closed by the quota (label `over-author-quota`) as a permanent "already exists": such a branch is
**retryable** once a short back-off (`UNSORRY_QUOTA_RETRY_BACKOFF_S`, default 3600 s) has elapsed, so
a transient quota close genuinely returns the goal to the pool. OPEN/MERGED PRs, and PRs closed for
any *non-quota* reason, still block re-dispatch. The back-off prevents an open/close churn loop on a
freshly quota-closed branch under genuine contention.

Together these are churn-safe: with a sole contributor the cap equals the governor budget so nothing
is quota-closed (no churn), and the previously-stranded branches re-dispatch and drain. Under
contention, the fair share bounds each author and the back-off bounds retry rate.

## Consequences

- A sole contributor (the common case per the #6751 audit) drains at the full gate budget instead of
  stalling at half. The ~117 stranded `ohdearquant` branches re-dispatch and drain.
- Fairness under real multi-contention is unchanged in spirit (equal shares), now *correctly* sized
  to the actual budget and contributor count rather than a fixed 20.
- Trade-off (accepted, #6751): a lone contributor's low-value template flood will fill otherwise-idle
  gate capacity. ADR-106 difficulty-aware dispatch still deprioritises it the moment diverse work
  appears; the real lever for *valued* throughput remains supply diversification (#6751 C1).
- `tools/repo/` is not CODEOWNERS-gated, but `pr-admission.yml` and `swarm/agent.sh` are — this rides
  the code-owner review path (ADR-019).

## Alternatives considered

- **Raise the flat per-author cap to 40.** Fixes the sole-contributor case but breaks fairness under
  contention (two authors could each hold 40 → one monopolises). Rejected for the contention-aware
  share.
- **Delete the branch on quota-close** (so "returns to the pool" is literally true). Doesn't recover
  branches already stranded with no running producer, and loses the verified proof on the branch.
  Rejected; the dispatcher-side un-strand recovers existing work.
- **Make the dispatcher fair-share-aware (never open an over-share PR).** Cleaner long-term (no PR is
  ever opened-then-quota-closed), but a larger change; the back-off achieves churn-safety now. Left
  as a follow-up.

REF: ADR-054 (per-contributor quota, amended here), ADR-058 (queued cutover / governor), ADR-106
(difficulty-aware dispatch), ADR-075 (solver fairness), #6751 (scaling roadmap). Implemented in
`tools/repo/pr_admission.py` (`fair_share_cap`), `.github/workflows/pr-admission.yml`, and
`swarm/agent.sh` (`queued_branch_has_pr` / `_blocking_pr_count`).
