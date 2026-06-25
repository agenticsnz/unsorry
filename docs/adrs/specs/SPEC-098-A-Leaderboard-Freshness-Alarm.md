# SPEC-098-A: Leaderboard Freshness Alarm + Refresh Timeout

Implements: [ADR-098](../ADR-098-Leaderboard-Freshness-Alarm.md) · Builds on [ADR-097](../ADR-097-Incremental-Leaderboard-Regen.md) (fast regen) · Reuses [SPEC-023-A](SPEC-023-A-Proof-Provenance-Leaderboard.md) (`generated_at` definition) · Status: Living · Updated: 2026-06-25

## What changed

Defence-in-depth so the published leaderboard can never go **silently** stale, and a hung refresh
fails loudly. No change to the regen, the artifacts, the trigger model, or the merge gates.

- **Added — `tools/leaderboard/freshness.py`:** a pure, unit-tested freshness gate.
- **Added — `timeout-minutes: 15`** on the `refresh` job in `.github/workflows/leaderboard.yml`.
- **Added — a "Freshness gate" step** that runs the gate against `origin/main` on every workflow
  invocation (push + cron) and turns the run red on a genuine stall.

## Freshness gate contract

`python3 -m tools.leaderboard.freshness [ROOT] [--threshold-minutes N]` (default `N = 30`).

1. Read the published board's `generated_at` from `ROOT/docs/metrics/leaderboard-ui.json`.
2. Compute the latest **board-source** commit time via `generate._latest_source_commit_z(ROOT)` —
   the same `_BOARD_SOURCE_PATHS` definition that *keys* `generated_at` (SPEC-023-A), so the two
   share one source of truth (DRY) and a freshly-published board reads as lag ≈ 0.
3. `lag = max(0, source_commit − generated_at)` seconds (clamped: a board at/ahead of the latest
   source is not stale).
4. Verdict:
   - **`stale`** (`lag > threshold`): print `::error title=Leaderboard stale::…` and **exit 1**.
   - **`fresh`** (`lag ≤ threshold`): print the lag and **exit 0**.
   - **`unknown`** (artifact absent/unreadable, or git unavailable): print a notice and **exit 0** —
     an indeterminate state never invents a false alarm.

Pure helpers (`lag_seconds`, `read_generated_at`, `evaluate`) carry the logic; `main` only parses
args, formats, and maps the verdict to an exit code. `--threshold-minutes` accepts a non-negative
integer (`--threshold-minutes N` or `=N`); anything else → exit 2 (usage error).

## Workflow wiring (`leaderboard.yml`)

- **`timeout-minutes: 15`** on the `refresh` job. The regen is ~10 s (ADR-097), so a job still
  *executing* after 15 min is hung, not slow. Counts execution time only — not the runner-queue
  wait — so it never false-kills a normal refresh.
- **Freshness step** (`if: always()`, after both the refresh and the no-token report-only paths):

      git fetch --quiet origin main
      git reset --hard --quiet origin/main
      python3 -m tools.leaderboard.freshness . --threshold-minutes 30

  It re-reads `origin/main` so it measures the **published** state — not this run's local regen —
  catching a lost push race or a starved pipeline that left `main` stale. Threshold 30 min matches
  the issue #6317 acceptance bound; a healthy board sits far under it.

## Coverage & limits

The gate runs on every workflow invocation, i.e. on **every push** (each landed merge → a run → a
check) and on each cron tick. So while merges are landing — exactly when staleness matters — every
merge re-checks freshness. The uncovered gap is a *quiescent, push-free* window where only the
throttled `*/15` cron ticks (~1×/hr under load); a stall there is caught at the next tick rather
than strictly within 30 min. Closing that gap needs the deferred ADR-098-neglected work (a
dedicated high-frequency monitor / serialized worker), tracked for a follow-up.

## Tests (`tools/leaderboard/tests/test_freshness.py`)

- `lag_seconds` — trailing source counts; equal → 0; board-ahead clamps to 0.
- `read_generated_at` — value read; missing / malformed / null → `None`.
- `evaluate` — `fresh` within threshold, `stale` past it (against real git history at controlled
  commit times), `unknown` with no artifact/git.
- `main` — exit 0 fresh, exit 1 + `::error::` annotation stale, `--threshold-minutes` flips the
  verdict, bad threshold → exit 2, indeterminate state never fails the run.
