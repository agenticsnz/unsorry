# SPEC-082-A: Single-Pass Leaderboard Refresh (`--write-if-stale`)

Implements: [ADR-082](../ADR-082-Single-Pass-Leaderboard-Refresh.md) · Refines [SPEC-036-A](SPEC-036-A-Targets-Board-Post-Merge-Refresh.md) (post-merge model) · Builds on [SPEC-023-A](SPEC-023-A-Proof-Provenance-Leaderboard.md) (data model + determinism) · Status: Living · Updated: 2026-06-22

## What changed

The post-merge leaderboard refresh recomputes the corpus **once** per run instead of twice.

- **Added — `tools.leaderboard --write-if-stale`:** a new CLI mode that computes the seven
  generated artifacts exactly once, writes them **iff** at least one differs from disk, and
  returns its result through the exit code.
- **Changed — `.github/workflows/leaderboard.yml`:** the standalone `--check` drift-probe step
  and the separate `--write` step are replaced by a single step that calls `--write-if-stale`.
- **Unchanged:** the artifacts produced, the trigger model (push primary + sparse cron backstop),
  the `[skip ci]` docs-only commit, the cheap-push-retry/rebase loop (#426), and the determinism
  guarantees of SPEC-023-A (`generated_at` keyed to the latest source commit, sorted JSON).

## `--write-if-stale` contract

`python3 -m tools.leaderboard --write-if-stale [ROOT]`

1. Render all seven artifacts from `ROOT` (default `cwd`) — one recompute:
   `docs/leaderboard.md`, `docs/leaderboard.svg`, `docs/proofs-over-time.svg`,
   `docs/metrics/community-stats.json`, `docs/metrics/leaderboard-ui.json`,
   `docs/metrics/attribution-gaps.json`, `docs/metrics/sourcing-leaderboard.json`.
2. Compute the set of **stale** artifacts (file absent, or on-disk bytes ≠ rendered bytes).
3. If the set is empty → write nothing, **exit 0** (in sync).
4. Otherwise → write **all** artifacts, print the stale paths to stderr, **exit 1** (was stale,
   now rewritten).

Exit-code semantics deliberately mirror `--check` (`0` = in sync, `1` = drift), with the added
side effect of writing. `--write-if-stale` is mutually exclusive with `--check`, `--write`, and
`--json` (passing more than one mode → exit `2`, usage error).

The staleness comparison and the write are the **single shared definition** also used by `--check`
and `--write` (`stale_paths()` / `write_all()` over one `artifacts` tuple in
`tools/leaderboard/generate.py::main`), so the three modes can never diverge (DRY, protocol §12).

### Idempotency / determinism

Because the artifacts are a pure function of `goals/` + `library/index` + `packages/**` +
`proof-runs/` + `contributor-aliases.json`, and `generated_at` is the committer time of the latest
commit touching those source paths (not wall-clock), `--write-if-stale` is a clean no-op once in
sync: a second invocation finds no stale paths and exits 0 without rewriting. This is what makes a
no-drift cron tick cheap and keeps the refresh's own `[skip ci]` commit from re-triggering drift.

## Workflow wiring

`.github/workflows/leaderboard.yml`, job `refresh` (token present — the hot path):

```
git fetch --quiet origin main
git reset --hard --quiet origin/main          # regenerate against the freshest main
if python3 -m tools.leaderboard --write-if-stale .; then
  echo "leaderboard already in sync with latest main — nothing to push"; exit 0
fi
git add $paths && git commit -q -m "docs: refresh leaderboard [skip ci]"
# …unchanged #426 push-retry loop; rebase-conflict fallback also uses --write-if-stale…
```

The no-`REFRESH_TOKEN` degraded path runs a single read-only `--check` purely to emit the
report-only warning (issue #417); perf is irrelevant there since it cannot push.

## Acceptance criteria

- `--write-if-stale` returns `1` and writes all seven artifacts when they are absent/stale, after
  which `--check` returns `0`. *(test: `test_write_if_stale_writes_once_and_signals_drift`)*
- `--write-if-stale` returns `0` and leaves artifacts byte-identical when already in sync, and stays
  a clean no-op on repeat. *(test: `test_write_if_stale_is_a_noop_when_in_sync`)*
- A single tampered artifact is detected and repaired in one pass. *(test:
  `test_write_if_stale_rewrites_only_the_drifted_artifact`)*
- `--write-if-stale` combined with any other mode exits `2`. *(test:
  `test_write_if_stale_is_mutually_exclusive_with_other_modes`)*
- The pre-existing `--check`/`--write` behaviour is unchanged (the full `tools/leaderboard` suite
  remains green after the DRY refactor).

## Out of scope

Speeding the ~10-min regen itself (incremental/cached recompute) and any change to what
`verified_proofs` counts (active+archive per ADR-041) are deferred to separate work.
