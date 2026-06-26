# SPEC-094-A: Publish Library Oleans on PRs

Implements: [ADR-094](../ADR-094-Publish-Library-Oleans-On-PRs.md) · extends [SPEC-045-A](SPEC-045-A-Gate-A-Library-Build-Cache.md) · Status: Living · Updated: 2026-06-24

Make `gate-a-prepare` publish its freshly-built library oleans to the ADR-045
fallback cache on **PRs** as well as `main`, so every audit/replay shard (ADR-063/091)
restores the exact-`<sha>` oleans and never cold-rebuilds (#5751). Soundness and the
restore side are unchanged; this only populates the cache the shards already read.

## 1. The change (`.github/workflows/gate-a.yml`)

The `gate-a-prepare` step *"Publish library oleans to fallback cache"* loses its
`main`-only guard:

- **Before:** `if: active == 'true' && github.ref == 'refs/heads/main' && prepare_volume == 'true'`
- **After:** `if: active == 'true' && prepare_volume == 'true' && (github.event_name != 'pull_request' || github.event.pull_request.head.repo.fork != true)`

Unchanged: `continue-on-error: true`, `uses: actions/cache/save@…`, `path:
.lake/build`, and the key `lake-build-<runner.os>-<hashFiles(lean-toolchain,
lake-manifest.json, lakefile.toml)>-<github.sha>`. The fork clause skips fork-PR runs
whose read-only `GITHUB_TOKEN` cannot write the cache (the save would 403); main
pushes (`github.event_name != 'pull_request'`) always publish, as today.

**Restore side: no change.** The audit (`gate_a_audit`) and replay (`gate_a_replay`)
shards keep their *"Fallback restore of library oleans on a cold volume"* step —
`actions/cache/restore` with the same exact-`<sha>` key + `lake-build-<os>-<hash>-`
restore-keys. Within one run all jobs share `github.sha`, so a PR shard now gets an
**exact-key hit** on what `prepare` just saved, and its `lake build UnsorryLibrary
--wfail` is an incremental no-op.

## 2. Why it is safe (normative)

- **Strict superset / graceful degradation.** The step is `continue-on-error` and
  non-gating. Save succeeds → shard restores exact oleans. Save fails or the entry is
  evicted → shard falls back to the prefix restore-key — **today's behaviour**. The
  change can only help or be neutral; it can never make a shard *worse* than main-only.
- **Soundness unchanged (SPEC-045-A / SPEC-049-A §2 / §3.1).** A restored olean is
  trusted-CI-built, never a contributor artifact; `leanchecker` + `axiom_audit`
  re-check every olean they load, and Lake rebuilds any whose source changed. The
  cache is a build accelerator, never a trusted input to a verdict. **No
  `download-artifact` is introduced** (the conformance string-guard holds).
- **Same-run scope.** GitHub Actions cache scoping lets jobs in the same run restore
  a cache saved earlier in that run (shared ref scope); cross-branch isolation is
  irrelevant to the intra-run prepare→shard handoff.

## 3. Conformance

- **No-artifact guard intact:** `gate-a.yml` still contains no artifact-download step
  (existing `test_decentralised_runner_conformance.py` assertion).
- **Restore key unchanged:** a test/grep asserts the `prepare` publish key and the
  shard restore keys remain byte-identical (the handoff only works if they match).
- **Non-gating:** the publish step stays `continue-on-error: true`; no required job
  `needs:` it.

## 4. Validation (production, ADR-058 spirit)

This is a change to a **non-gating cache step inside an existing job** — not a
required-check routing change — so it ships directly and is **validated in
production**: after it lands, monitor the audit-shard timing distribution (**median
and tail**) and the cold-volume fallback hit-rate on new proof PRs. Success = the
cold-build tail (the 1077 s class) disappears and runner-minutes/PR fall, with **no
warm-median regression** from faster cache churn. Revert (re-add the `main`-only
clause) if the median regresses.

## 5. Out of scope

- A Namespace cross-runner / run-shared volume (ADR-046 exposes only per-runner).
- Artifact-based handoff (forbidden by SPEC-049-A §2).
- Sharding the daily full backstop; intra-runner `--jobs > 1` (SPEC-091-A §6).
