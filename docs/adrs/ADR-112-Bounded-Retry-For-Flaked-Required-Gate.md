# ADR-112: Bounded Auto-Retry for PRs Blocked by a Flaked Required Gate

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-112 |
| **Initiative** | corpus throughput & merge reliability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-29 |
| **Status** | Accepted |

## Context

A merged proof reaches `main` only when its PR passes the required gates and
auto-merge (ADR-005) fires. Gate A's soundness check includes `gate-a-replay`, a
full-Mathlib Lean job (ADR-048/049), which is **occasionally flaky**: it runs and
fails for an infrastructure reason — runner eviction, cache miss, a transient
timeout — not because the proof is unsound.

When that happens the PR sits `BLOCKED` with auto-merge enabled but unable to
fire, and **nothing re-runs it**. The dropped-gate janitor (ADR — `dropped-gate-janitor.yml`,
`tools/repo/dropped_gate_prs.py`) only rescues the *never-dispatched* signature (a
required gate with **zero** check-runs on the head SHA); its guards explicitly
leave a gate that *ran and failed* alone — "a real block, not a drop". So a
**flaked** Gate A failure has no recovery path: it requires a human to notice and
`gh run rerun`.

Observed 2026-06-29: seven sound `mac-158f` difficulty-1 proofs (`gself-pow-*`,
valid by cofactor + `ring`) sat `BLOCKED` for ~63 h on a flaked `gate-a-replay`.
With the proving agents also offline, this left the swarm landing **zero proofs
for ~63 h**. Re-running the failed jobs made every one pass and auto-merge — i.e.
a one-line retry would have recovered the whole backlog days earlier.

The hard part is telling a flake from a real failure. We cannot, in advance. But
a flake passes on retry and a real failure does not, so a **bounded** retry — re-run
a failed gate a small fixed number of times, then stop — recovers flakes while
letting a genuinely unsound proof settle into a real, human-surfaced block.

## WH(Y) Decision Statement

**In the context of** Gate A's replay being occasionally flaky and auto-merge
being unable to fire on a failed required gate,

**facing** a flaked Gate A failure leaving a *sound* PR `BLOCKED` indefinitely
with no automated recovery — the dropped-gate janitor covers only never-dispatched
gates, not flaked ones — which on 2026-06-29 froze the entire swarm's proof
landings for ~63 h,

**we decided for** a sibling janitor `tools/repo/flaky_gate_retry.py` +
`gate-a-flake-retry.yml` that detects an open, non-draft, auto-merge-enabled,
`BLOCKED`/`UNKNOWN` PR whose required gate (default: `gate-a`) is in a terminal
non-pass state with no required gate still pending, and **re-runs that gate's
failed jobs** (`gh run rerun --failed`), **bounded** by the workflow run's
`run_attempt` so each gate is retried at most `--max-attempts` (default 3: the
original run + 2 retries) before being left `BLOCKED` and surfaced,

**and neglected** retrying unboundedly (rejected — a genuinely failing proof would
loop forever, burning CI and never surfacing), folding this into the dropped-gate
janitor (rejected — opposite signal (failed vs absent) and a different action
(rerun vs update-branch) needing `actions: write`; a separate, single-responsibility
tool is clearer and keeps the janitor read-only), and trying to *classify* flake
vs real failure up front (rejected — not reliably possible; a bounded retry is the
empirical test),

**to achieve** automatic recovery of flaked Gate A failures — sound PRs land
without human intervention — while a real failure deterministically converges to a
bounded, visible block,

**accepting that** a real (non-flaky) failure now costs up to `max-attempts-1`
extra CI re-runs before it settles (bounded and small), and that the retry acts
only on auto-merge-enabled PRs (a PR without auto-merge is assumed still in
authoring and is left alone).

## Decision

- `flaky_gate_retry.flaky_retry_reason(...)` is the pure predicate: retry iff the
  PR is non-draft, auto-merge-enabled, `BLOCKED`/`UNKNOWN`, a required gate is in
  `TERMINAL_NONPASS`, no required gate is pending, the PR is older than
  `--min-age-minutes`, and the gate's `run_attempt < --max-attempts`.
- The I/O shell maps each flaked required gate to its workflow run (parsed from
  the check-run `details_url`), reads `run_attempt`, and on `--apply` issues
  `gh run rerun <run-id> --failed`.
- `gate-a-flake-retry.yml` runs it on `workflow_run: gate-a completed` (primary) +
  hourly cron (backstop) + manual, with `actions: write` and the default
  `GITHUB_TOKEN` (re-running an existing run needs no PAT, unlike the janitor's
  update-branch).

## Consequences

- Flaked Gate A failures self-heal; the swarm no longer needs a human to re-run a
  sound but unlucky PR. The ~63 h class of outage is closed.
- Bounded: a genuinely failing proof is retried at most twice, then left `BLOCKED`
  and reported — no infinite loop, CI cost capped.
- Single responsibility: the dropped-gate janitor (never-dispatched) and this
  retry (flaked) are complementary and independently testable; together they cover
  both ways a required gate can leave a PR stuck.
- The shared, pure helpers (`normalize_run_state`, `PENDING_STATES`,
  `TERMINAL_NONPASS`) are reused from `dropped_gate_prs`, so the two tools agree on
  what "pending" and "failed" mean by construction.
