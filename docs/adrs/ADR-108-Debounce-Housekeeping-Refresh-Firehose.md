# ADR-108: Debounce the post-merge housekeeping refresh firehose

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-108 |
| **Initiative** | throughput / plumbing (roadmap #6751 §7 B1, lever L4) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-29 |
| **Status** | Proposed |

## Context

A scaling audit (#6751, 2026-06-26 NZT) found that **66% of commits to `main` are not proofs** —
they are post-merge *housekeeping refreshes*: the `docs: refresh … [skip ci]` /
`chore: relabel … [skip ci]` commits that regenerate the leaderboard, the targets/queue boards,
the proofs visualisation, the ADR index, and the attribution relabel. Five workflows push these,
each triggered `on: push: branches:[main]` whenever a proof merge touches their inputs:

- `leaderboard.yml`, `proofs-visualisation.yml`, `targets-board.yml`, `adr-index.yml`,
  `attribution-relabel.yml`.

At the swarm's merge rate (~20/h, peaks far higher) this is a self-inflicted firehose. It is not a
correctness problem — `[skip ci]` keeps the refresh commits from re-triggering CI, and each
workflow's `concurrency` group (`cancel-in-progress: false`) already coalesces *bursts* into at
most one in-progress + one pending run. But the **steady-state** rate is ~one refresh-push per
qualifying merge, and that:

1. spends the single central `REFRESH_TOKEN` PAT (5000/h) — the first true platform limit at ~10×
   (#6751 §3),
2. churns the `main` merge surface the autonomous squash-merge (ADR-005) runs on, and
3. drives the `cancel-in-progress` janitor/coalescing churn.

The audit named this **lever L4 / roadmap item B1**: take the refreshers off the per-merge path.

**The naive fix has already failed twice.** The history encoded in `leaderboard.yml`'s own header:
a cron-only model (#426) relied on a `*/10` schedule, but **GitHub throttles this repo's scheduled
workflows to ~1×/hr regardless of the cron expression**, leaving the board 1–2 h stale (#3720) —
so `push` was deliberately restored as primary (#3735). "Tune the cron tighter" therefore does
**not** work here; schedule-only re-introduces the staleness saga ADR-098/#6317 then built a
freshness gate to alarm on.

## Decision

**Keep the `push` trigger as the primary, low-latency path on all five refreshers, and add a
min-interval *debounce guard* that skips a push-triggered refresh when the same refresh already
landed within a tunable window (default 600 s / 10 min).** Schedule and `workflow_dispatch` runs
are never debounced — they remain the backstop / manual path.

- The guard is a single, unit-tested helper `tools/repo/refresh_debounce.py`. Each workflow runs
  it once (only on `push` events) and gates its existing refresh step on the result:
  `if: …present == 'true' && steps.debounce.outputs.skip != 'true'`.
- It matches the workflow's own refresh-commit subject in `git log` (full history — every refresher
  already checks out `fetch-depth: 0`) and compares that commit's time to now: skip iff
  `now − last_refresh < window`. No prior refresh ⇒ never skip (fail-open to a refresh).
- Window is a repo var `UNSORRY_REFRESH_DEBOUNCE_SECONDS` (default `600`); `0` disables the guard
  (every push refreshes — today's behaviour), so the change is fully reversible without a code edit.
- The three refreshers that lacked any schedule (`proofs-visualisation`, `targets-board`,
  `adr-index`) gain a sparse `*/15` cron **backstop** (throttled to ~1×/hr in practice) so the
  *final* batch before a quiet period is always flushed even if no further merge arrives — the same
  push-primary + cron-backstop shape `leaderboard.yml` and `queue-board.yml` already use.

### Why this is safe against the freshness gate (the #3720 trap)

`leaderboard.yml`'s freshness gate (ADR-098, `tools/leaderboard/freshness.py`) alarms when the
published board trails **the latest board-source commit** by more than 30 min. Crucially that lag
is **commit-time relative, not wall-clock**: `lag = latest_source_commit − published_generated_at`.
The debounce only ever skips a push when a refresh landed `< window` ago, so during activity the
next merge past the window refreshes and the board's `generated_at` can trail the latest source by
at most ~`window`; during a quiet period the lag is *frozen* at ≤ `window` (both terms are commit
times). With `window` (10 min) well below the gate's 30 min threshold, the debounce can never trip
the freshness alarm. This is the property cron-only lacked: cron throttling let wall-clock — and
thus the source-relative lag — grow to 1–2 h.

## Consequences

- Refresh-push rate to `main` drops from ~per-merge to ≤ `1/window` per workflow during sustained
  activity (≈ 6/h each at the default), directly relieving constraints (1)–(3) above. First-merge
  latency after a quiet period is unchanged (push fires immediately; the guard only fires when a
  refresh is already recent).
- A board may trail the latest merges by up to `window` during bursts — an explicit, bounded
  trade the audit accepts for a human-facing board; the leaderboard freshness gate continues to
  guarantee the 30-min bound.
- The guard logic is in `tools/repo/` (not a CODEOWNERS-gated path), but the workflow wiring is in
  `.github/` (gated, trust surface) — this change rides the code-owner review path per ADR-019.

## Alternatives considered

- **Schedule-only (drop `push`).** Rejected: re-creates #3720 (cron throttled to ~1×/hr → 1–2 h
  stale) and would fight the ADR-098 freshness gate.
- **Move refreshes off `main` to a scheduled snapshot branch / Pages artifact.** Larger change;
  the guild reads `docs/metrics/*.json` from `main` today (SPEC-023-A). Deferred — debounce is the
  minimal, reversible first cut B1 calls for.
- **Per-workflow inline bash guard.** Rejected for DRY/testability: the time arithmetic and the
  git lookup are identical across five workflows and must be unit-tested (agent-lint only shellchecks
  `swarm/*.sh`), so the logic lives in one tested Python helper.

REF: #6751 (roadmap §7 B1 / L4), ADR-082 (single-pass `--write-if-stale`), ADR-098 / #6317
(freshness gate), ADR-036 / #415 (post-merge generated-artifact model), ADR-005 (autonomous merge),
ADR-019 (gate/tooling TCB), #426 / #3720 / #3735 (the cron-vs-push saga). Implemented by
[SPEC-108-A](specs/SPEC-108-A-Debounce-Housekeeping-Refresh-Firehose.md).
