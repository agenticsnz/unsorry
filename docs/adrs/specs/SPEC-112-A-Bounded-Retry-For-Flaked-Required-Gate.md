# SPEC-112-A: Bounded Auto-Retry for a Flaked Required Gate

Implements: [ADR-112](../ADR-112-Bounded-Retry-For-Flaked-Required-Gate.md) · Status: Living · Updated: 2026-06-29

ADR-112 adds a sibling to the dropped-gate janitor that re-runs a *flaked*
required gate (one that ran and failed), bounded so a genuinely failing proof
stops being retried. This spec is the contract.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | `flaky_retry_reason(...)` pure predicate + `run_id_from_details_url(...)` | `tools/repo/flaky_gate_retry.py` | no |
| D2 | I/O shell: per-gate latest run + `run_attempt`, `gh run rerun --failed` on `--apply` | same | no |
| D3 | `gate-a-flake-retry.yml` (workflow_run gate-a + cron backstop + manual; `actions: write`) | `.github/workflows/gate-a-flake-retry.yml` | **yes** (`/.github/` @cgbarlow) |
| D4 | Tests for the pure predicates (positive, bounded, every guard) | `tools/repo/tests/test_flaky_gate_retry.py` | no |

## 2. Predicate (D1)

`flaky_retry_reason(required, present_states, attempts, merge_state, is_draft,
auto_merge, age_minutes, min_age_minutes, max_attempts) -> (reason|None, retry_list)`.
Returns a non-`None` reason **iff** all hold:

- not draft and `auto_merge` is truthy;
- `merge_state` in `{BLOCKED, UNKNOWN}`;
- no required context in `PENDING_STATES` (a still-running gate may yet pass);
- at least one required context in `TERMINAL_NONPASS`;
- `age_minutes >= min_age_minutes`;
- at least one failed context with `attempts.get(c, 1) < max_attempts` (those are
  the `retry_list`).

`PENDING_STATES`/`TERMINAL_NONPASS`/`normalize_run_state` are imported from
`dropped_gate_prs` — single definition of "pending"/"failed" across both tools.

## 3. Shell (D2)

- List open PRs with `autoMergeRequest` in the `--json` set; skip draft /
  non-`BLOCKED`/`UNKNOWN` / no-auto-merge.
- For each, fetch head-SHA check-runs, keep the latest per required context with
  its `details_url`; parse the run id (`run_id_from_details_url`); read
  `run_attempt` via `repos/{repo}/actions/runs/{id}`.
- On `--apply`: `gh run rerun <run-id> --failed` for each retryable gate's run.
  **Rebase fallback:** GitHub refuses to re-run a run older than a few days, so a
  queued branch that flaked days ago then got dispatched cannot be rerun at all
  ("This workflow run cannot be retried"). When the rerun is rejected, fall back to
  `update-branch` (rebase → fresh `synchronize` → gates re-dispatch on a current
  SHA), exactly like the dropped-gate janitor. `--no-rebase` disables the fallback
  for token-less (rerun-only) runs, since a default-token `synchronize` won't
  re-dispatch. A PR neither rerunnable nor rebasable (e.g. a conflicting ancient
  branch) is reported, not silently dropped.
- Report counts (`retried`, `rebased`); list PRs that have **exhausted**
  `--max-attempts` (left BLOCKED for a human) — never silently drop them.
- Defaults: `--required gate-a`, `--max-attempts 3`, `--min-age-minutes 15`,
  `--limit 20`. Dry-run unless `--apply`; rebase fallback on unless `--no-rebase`.

## 4. Workflow (D3)

`on: workflow_run [gate-a completed] + schedule (cron "41 * * * *") + workflow_dispatch`.
`permissions: contents: read, pull-requests: read, actions: write`.
`concurrency: gate-a-flake-retry, cancel-in-progress: false` (coalesce).
`GH_TOKEN: ${{ secrets.REFRESH_TOKEN || github.token }}` — a rerun needs only
`actions: write`, but the rebase fallback's `synchronize` only re-dispatches the
gates under a non-default token, so it prefers `REFRESH_TOKEN`. A `Detect refresh
token` step passes `--no-rebase` when the secret is absent (rerun-only, no futile
rebase). `--apply` unless a manual dry-run (`inputs.apply == 'false'`).

## 5. Tests (D4)

Positive (failed gate, attempt < max → retry); each terminal state
(failure/timed_out/startup_failure/cancelled) is retryable; bounded (attempt ==
max → no retry; attempt == max-1 → retry); guards (auto-merge off, draft,
non-BLOCKED, passing gate, a pending required gate, too-fresh, absent-attempt
defaults to 1); `run_id_from_details_url` parse + none. The existing
`test_dropped_gate_prs.py` suite stays green (shared helpers unchanged).

## 6. Out of scope

Distinguishing flake from real failure up front (the bounded retry IS the test);
retrying Gate B (fast hygiene, effectively never flakes — overridable via
`--required`); any change to the dropped-gate janitor.
