# ADR-114: Rebase-First Recovery When a Flaked-Gate PR Is Behind Its Base

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-114 |
| **Initiative** | corpus throughput & merge reliability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-30 |
| **Status** | Proposed |
| **Amends** | [ADR-112](ADR-112-Bounded-Retry-For-Flaked-Required-Gate.md) |

## Context

ADR-112 added `tools/repo/flaky_gate_retry.py`: when a sound PR sits `BLOCKED`
because a required gate *flaked* (ran and failed for an infrastructure reason),
the janitor re-runs the gate's failed jobs (`gh run rerun --failed`), bounded by
`run_attempt` so a genuinely failing proof converges to a visible block. A later
fix added a **rebase fallback** (`update-branch`) for the one case GitHub *refuses*
to re-run — a workflow run "older than a few days".

That covers two recovery triggers (rerun, and rebase-when-rerun-is-rejected) but
misses a third, now-common failure mode: a **base-staleness** failure on a *recent*
run. Gate A's `gate_a_prepare` restores the library oleans a prior `main` build
published, keyed to the PR's **base commit**, so `lake build UnsorryLibrary
--wfail` is an incremental no-op. When a PR's branch falls **behind `main`**, that
published-cache key is superseded/evicted, prepare **cold-builds the whole library
from scratch**, and exceeds its 45-minute `timeout-minutes` cap. The required
`gate-a` check fails — not a flake, not a never-dispatched drop, but a
*deterministic* consequence of base drift.

For this case ADR-112's primary action is actively wrong: `gh run rerun --failed`
on a *recent* run is **accepted** (not rejected), so the rebase fallback never
fires; the rerun re-runs `gate_a_prepare` **on the same stale base**, cold-builds
again, times out again, and after `--max-attempts` the PR is parked `BLOCKED` for a
human — having burned ~3×45 min of runner time to no effect. The only action that
clears it, `update-branch` (rebase onto current `main` → warm published cache →
prepare incremental → gates re-dispatch on a fresh SHA), is unreachable because it
is gated behind *rerun rejection*, which a recent run never produces.

Observed 2026-06-30: PR #7056 (`gself-pow-…-add-pow-nine`, a sound `mac-158f`
proof) sat `BLOCKED` ~20 h, 2 commits behind `main`, on repeated 45-min cold
`gate_a_prepare` timeouts. This is exactly the cold-build / cache-warming tail
tracked by #5751 (and #1921), surfacing as a stranded PR rather than as raw runner
cost. The dropped-gate janitor (never-dispatched) and ADR-112's rerun (transient
flake) between them still leave a base-stale PR with no automated recovery.

The discriminator is already computable: `dropped_gate_prs._behind_by(repo, base,
sha)` returns how many commits the head is behind its base. A rerun cannot clear a
base-staleness failure; a rebase can — and when `behind_by == 0` an `update-branch`
is a no-op, so the choice is unambiguous from that one number.

## WH(Y) Decision Statement

**In the context of** ADR-112's flaked-gate retry, whose primary action is to
re-run a failed required gate's jobs on the **same head SHA**,

**facing** a base-staleness failure class — a branch behind `main` whose
`gate_a_prepare` cold-builds the library (its published-olean cache key superseded)
and times out at 45 min — where re-running the same stale SHA reproduces the
failure deterministically and the curative `update-branch` is unreachable (it fires
only when GitHub *rejects* a rerun, which a recent run never does), so a sound PR is
parked `BLOCKED` after burning the full retry budget (observed: #7056),

**we decided for** making the recovery action **branch-state aware**: a pure
`recovery_action(behind_by, no_rebase)` that returns `"rebase"` when the branch is
behind its base and rebase is available (a non-default `REFRESH_TOKEN` enables the
`synchronize`), else `"rerun"`. Behind base ⇒ `update-branch` first (warm cache,
fresh SHA), falling through to a rerun only if the rebase cannot apply
(conflict/race); up to date ⇒ the unchanged ADR-112 path (rerun, then rebase if the
rerun is rejected). `behind_by` is read once per confirmed candidate via the
existing `_behind_by` helper,

**and neglected** raising or removing `gate_a_prepare`'s `timeout-minutes` (rejected
— masks the cold tail without fixing it, and a longer cold build still wastes a full
runner; that is #5751's warm-seed remit, not the retry's), *always* rebasing every
flaked PR regardless of `behind_by` (rejected — when up to date an `update-branch`
is a no-op/error and a plain rerun is the correct, cheaper transient-flake recovery,
and a needless rebase re-dispatches the full gate instead of just the failed jobs),
and classifying "cold-build timeout" from log text (rejected — brittle; `behind_by >
0` is a robust, side-effect-free proxy for "a rerun of this SHA can't help"),

**to achieve** automatic recovery of base-stale flaked PRs — they rebase onto a
warm base and merge without human intervention — while transient flakes keep the
cheaper same-SHA rerun and the bounded-attempt convergence is preserved,

**accepting that** the rebase-first path requires `REFRESH_TOKEN` (without it the
workflow runs `--no-rebase` and a base-stale PR degrades to the pre-ADR-114
rerun-until-exhausted-then-surfaced behaviour — no worse than today), that a rebase
re-dispatches the full gate rather than only the failed jobs (correct work, modestly
more CI than a `--failed` rerun), and that this is recovery, not prevention — the
durable fix for cold prepare is #5751's warm-seed/`.lake` handoff.

## Decision

- New pure function `flaky_gate_retry.recovery_action(behind_by, no_rebase) ->
  {"rebase","rerun"}`: `"rebase"` iff `behind_by > 0 and not no_rebase`, else
  `"rerun"`. Unit-tested in isolation (behind/ahead × rebase-enabled/disabled).
- The detect loop reads `behind_by` once per **confirmed** candidate
  (`_behind_by(repo, baseRefName, headRefOid)`, reusing the dropped-gate helper —
  one `compare` call, bounded by `--limit`) and carries it on the candidate.
- The act loop dispatches on `recovery_action`: `"rebase"` → `update-branch`
  (fall through to rerun if it cannot apply); `"rerun"` → the unchanged ADR-112
  rerun, with the existing rebase-on-rerun-rejection fallback intact.
- No new flag and no workflow change: the existing `--no-rebase` (set by
  `gate-a-flake-retry.yml` when `REFRESH_TOKEN` is absent) already disables every
  rebase path, so a token-less run is unaffected. `recovery_action` honours it.

## Consequences

- Base-stale flaked PRs self-heal by rebasing onto a warm base; the #7056 class
  (a sound proof stranded on a cold-prepare timeout it can never rerun past) is
  closed, and the retry stops burning ~3×45 min of runner time re-running a build
  that cannot pass.
- Transient flakes are unchanged: up-to-date PRs still take the cheaper same-SHA
  `--failed` rerun, and the bounded `--max-attempts` convergence is untouched.
- Dependency is honest: with no `REFRESH_TOKEN` the rebase paths are off and a
  base-stale PR degrades exactly to today's behaviour (rerun to exhaustion, then
  surfaced) — strictly no regression.
- The two janitors plus ADR-112's three triggers (never-dispatched → rebase;
  transient flake → rerun; stale-run rerun-rejection → rebase; **base-stale →
  rebase-first**) now cover every way a required gate leaves a sound PR stuck.
- This is a recovery patch, not the cold-build fix: it removes the *stranding*
  symptom while #5751 (warm-seed / reliable `.lake` olean handoff) removes the
  *cold build* itself.
