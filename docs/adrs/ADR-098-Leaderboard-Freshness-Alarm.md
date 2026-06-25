# ADR-098: Leaderboard Freshness Alarm + Refresh Timeout (defence-in-depth)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-098 |
| **Initiative** | unsorry — leaderboard publish reliability under a high merge cadence |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-25 |
| **Status** | Accepted |

## Context

ADR-101 cut the leaderboard regen from ~64 min to ~10 s, so the published board
(`docs/metrics/leaderboard-ui.json`, read live by `agenticsnz/unsorry-guild`) now tracks `main`
within minutes under the normal merge flood. That fixes the *root cause* of issue #6317, but the
issue also asked for **defence in depth** (its proposals #2/#3): even with a fast regen, the board
can still fall behind for reasons outside the regen's control —

- a lost push race (the #426 retry loop can exhaust its attempts under a sustained burst),
- runner-queue starvation (observed ~7–8 min queue waits before a run executes; #2172/#3177),
- the `*/15` cron backstop being throttled by GitHub to ~1×/hr during busy periods (#3720),
- or a future regression that silently slows or breaks the regen again.

Today such a stall is **silent**: the board simply serves hours-old standings with no signal at
the source. The guild added a client-side `generated_at` "may be lagging" indicator, but that is a
read-side band-aid — nothing on `main` asserts that the published artifact is actually fresh, and
nothing fails loudly when it is not. Issue #6317's acceptance criteria require that the artifact
never go far stale while merges land *without emitting a visible failure/alert*.

## WH(Y) Decision Statement

**In the context of** a now-fast post-merge leaderboard refresh whose published artifact still
depends on winning a push race and on the runner/cron actually firing,
**facing** the residual failure mode that the board can fall hours behind **silently** — a lost
push race, a starved/throttled runner, or a future regen regression — with nothing on `main` that
asserts freshness or fails visibly,
**we decided for** adding a **freshness gate** — an in-repo, unit-tested
`tools.leaderboard.freshness` that compares the published `leaderboard-ui.json` `generated_at`
against the latest board-source commit (reusing `generate._latest_source_commit_z` /
`_BOARD_SOURCE_PATHS`, the same definition that *keys* `generated_at` — SPEC-023-A — so the two can
never drift) and, past a 30-min threshold, emits a GitHub `::error::` annotation and exits non-zero
(turning the run red); the workflow runs it on **every** invocation (push + cron) against
`origin/main` (the truly-published state, not the run's local regen), and we add `timeout-minutes:
15` to the refresh job so a hung run fails loudly instead of producing nothing,
**and neglected** a dedicated long-lived / self-hosted serialized refresh worker and a
self-rescheduling cron backstop (issue #6317 proposal #2) — heavier infra (a new always-on runner,
or a workflow that re-dispatches itself with its runaway-loop and auto-disable-on-inactivity
footguns) that is unwarranted now that the regen is seconds and the board tracks within minutes;
throttling the proof-merge firehose (#6317 proposal #3) — it would slow the swarm to paper over a
publish problem; and making freshness a *required PR status check* — it is a property of `main`'s
published state over time, not of a diff, so it belongs on the post-merge/cron workflow, not the
merge gate,
**to achieve** issue #6317's acceptance criterion that a stale board (>30 min behind while merges
land) surfaces a **visible** red alarm rather than silently serving old standings, and that a hung
refresh fails fast — closing the loop the fast regen opened,
**accepting that** the alarm's *coverage cadence* is bounded by how often the workflow runs (every
push, plus the throttled cron) — so a total stall during a quiescent, push-free window could
out-run the 30-min bound until the next tick; this is acceptable because stalls matter precisely
*while merges are landing* (every such merge triggers a run, hence a check), and the dedicated
high-frequency monitor that would close even the quiescent gap is the deferred proposal-#2 work.

## Consequences

- **Positive.** The board can no longer go silently stale: any genuine publish stall (lost push,
  starvation, regression) trips a visible red run with a precise lag message; a hung refresh is
  killed at 15 min. The gate is pure/in-repo and unit-tested (`tools/leaderboard/tests/
  test_freshness.py`), reuses the single `generated_at` source-of-truth (DRY), and is
  soundness-neutral — it observes generated artifacts, never the library/proofs/gates.
- **Negative / residual.** Coverage is only as frequent as the workflow runs (push + throttled
  cron), so a stall in a long push-free window is caught at the next tick, not necessarily within
  30 min. The serialized worker / self-rescheduling backstop that would guarantee the bound in all
  conditions is deferred (proposal #2). The 30-min threshold is a heuristic; if it proves noisy or
  slack it is a one-line change.
- **Builds on** ADR-101 (fast regen) and refines the ADR-036/082 post-merge model; does not change
  the trigger, push model, or the artifacts produced.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Freshness-alarm spec | Specification | specs/SPEC-098-A-Leaderboard-Freshness-Alarm.md |
| REF-2 | Fast regen this hardens | Decision | ADR-101-Incremental-Leaderboard-Regen.md |
| REF-3 | `generated_at` definition reused as the freshness source-of-truth | Spec | specs/SPEC-023-A-Proof-Provenance-Leaderboard.md |
| REF-4 | Single-pass refresh + push-retry loop | Decision/CI | ADR-082-Single-Pass-Leaderboard-Refresh.md · `.github/workflows/leaderboard.yml` |
| REF-5 | Diagnosis + acceptance criteria (defence-in-depth proposals) | Issue | https://github.com/agenticsnz/unsorry/issues/6317 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-25 |
| Accepted | unsorry maintainers | 2026-06-25 |
