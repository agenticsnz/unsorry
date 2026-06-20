# SPEC-048-B: Verify-on-Ingest Phase 2 — Incremental Push + Scheduled Backstop + Routine Runner Sizing

Implements: [ADR-048](../ADR-048-Verify-On-Ingest.md) (Phase 2) · Status: Living · Updated: 2026-06-15

## Behaviour

ADR-048 Phase 1 made archive moves provenance-only (no kernel replay). Phase 2 finishes the
verify-on-ingest shift so routine Gate A can be split across role-specific Namespace profiles:

1. **Push to `main` becomes incremental.** Previously every push to `main` ran a FULL kernel replay +
   FULL axiom audit (the post-merge backstop). It now replays/audits only the **pushed diff** — the
   changed library modules + their reverse-import closure (ADR-033) — exactly like a PR. The base is
   `github.event.before` (the previous `main` tip), so for a squash-merge the diff is precisely the
   merged change.
2. **A scheduled full replay is the new backstop.** `gate-a-full-replay.yml` runs daily (and on
   `workflow_dispatch`), replaying + auditing the WHOLE active library (no `--base`) and re-validating
   every archive package. This is the defense-in-depth re-derivation of soundness that the incremental
   push no longer does inline.
3. **Routine runs route by job role.** `detect` sends prepare/archive work to `namespace-profile-unsorry-prepare`, axiom
   audit to `namespace-profile-unsorry-audit`, and kernel replay to `namespace-profile-unsorry-replay`. Only an **olean-invalidating**
   change (`lean-toolchain`, `lakefile.toml`, `lakefile.lean`, `lake-manifest.json` — the
   `forces_full_replay` set) forces a FULL replay, but it still runs in the replay lane.
4. **A full replay can fit a constrained runner via a small chunk.** `UNSORRY_REPLAY_CHUNK` overrides
   `REPLAY_CHUNK_SIZE` so the serial full replay splits into smaller chunks; leanchecker holds ~all of
   mathlib resident per process, so a smaller chunk trims the few-olean peak on top of that image. The
   scheduled backstop sets it to `6`.

## Implementation

### `tools/gate_a/parallel_modules.py`

- `REPLAY_CHUNK_SIZE` is computed by `_replay_chunk_size()`, which reads `UNSORRY_REPLAY_CHUNK`
  (default `30`). A missing, non-integer, zero, or negative value falls back to `30` — a bad value can
  never disable chunking into one unbounded `leanchecker` process.
- `replay()` calls `_replay_chunk_size()` at run time (not the import-time constant) so the env
  override is honoured in-process.
- **No change** to the incremental scoping (`scoped_targets`, `scoped_audit_targets`,
  `forces_full_replay`, `forces_full_audit`): the PR-time kernel replay and audit are byte-for-byte the
  same. `#792` already narrowed `forces_full_replay` to the olean-invalidating set, so
  `tools/gate_a/**` and `gate-a.yml` changes run an incremental replay.

### `.github/workflows/gate-a.yml`

- `detect` emits role-specific Namespace runner outputs: `prepare_profile=namespace-profile-unsorry-prepare`,
  `audit_profile=namespace-profile-unsorry-audit`, `replay_profile=namespace-profile-unsorry-replay`, and
  `archive_profile=namespace-profile-unsorry-prepare`.
- Runner routing no longer depends on the `forces_full_replay` set. That set remains in
  `parallel_modules.py` and controls replay scope only.
- `gate_a_audit` and `gate_a_replay` set
  `BASE_SHA = pull_request.base.sha` on a PR, `github.event.before` on a push, empty otherwise. The
  step runs the FULL command when `BASE_SHA` is empty **or** the zero-SHA
  (`0000000000000000000000000000000000000000`, i.e. first push / branch creation); otherwise the
  incremental `--base "$BASE_SHA"` command. The existing two-branch command structure is preserved.
- `gate_a_archive` uses the **same `BASE_SHA` rule** as audit/replay: `pull_request.base.sha` on a PR,
  `github.event.before` on a push, empty otherwise — and the zero-SHA (first push / branch creation) or
  an empty `BASE_SHA` falls back to validating **all** archive packages (never relying on implicit
  `git diff <zero-sha>` behaviour on a soundness path). On a PR it validates provenance + packaging for
  the changed archives; on a normal push it is usually a no-op (no archive changed). Provenance
  enforcement at archive-introducing PRs is not weakened.

### `.github/workflows/gate-a-full-replay.yml` (new)

- `schedule: cron "11 4 * * *"` (daily) + `workflow_dispatch`; `concurrency: gate-a-full-replay`
  (`cancel-in-progress: false` — never abort an in-flight backstop).
- `runs-on: namespace-profile-unsorry-replay`; `env.UNSORRY_REPLAY_CHUNK: "6"`;
  `timeout-minutes: 180`.
- Steps mirror `gate_a_replay`: checkout `fetch-depth: 0`, Namespace `.lake` volume (ADR-046),
  best-effort swap, `lean-action` build of `UnsorryGoals`, statement-binding generation,
  `lake build UnsorryLibrary --wfail`, then **full** `audit` and **full** `replay` (no `--base`), then
  `archive_packages validate-changed` (no `--base` = all archives, packaging from scratch).
- Failure surfaces per repo convention (cf. `reaper.yml`): `set -euo pipefail` + job failure → red
  scheduled run.

## Transition / compatibility

- **Zero-gap, additive:** the scheduled backstop ships in the **same** branch as the incremental-push
  change, so there is never a window with no full re-verify path. The push that lands this change still
  runs through Gate A.
- **PR-incremental path unchanged:** proof PRs replay/audit exactly as before.
- **Works after downscale:** routing depends on job role, not on a hidden runner size. The current
  operator model keeps prepare/archive on `namespace-profile-unsorry-prepare`, audit on `namespace-profile-unsorry-audit`, and replay on
  `namespace-profile-unsorry-replay`. The scheduled backstop uses the replay lane with the small-chunk path.
- **Provenance check unchanged:** `archive_proof_provenance` still runs at every archive PR.

## Safety

Lean soundness is unchanged. Every proof is still kernel-replayed once by the trusted pipeline under
its pinned toolchain/mathlib — now at PR time and re-verified on the pushed diff, plus the daily full
backstop. A context change (ADR-033 triggers) still forces a full re-verify. The risk shift is the same
*bookkeeping* risk ADR-048 already accepted (knowing the on-`main` olean is the verified one), now
backstopped daily instead of per-push. The trust boundary remains "CI verified this exact artifact +
immutability," never a prover's attestation.

## Acceptance criteria

- `UNSORRY_REPLAY_CHUNK=6` splits a 30-module replay into 5 chunks; every module still replayed.
  (`test_replay_chunk_size_env_override_shrinks_chunks`.)
- A bad `UNSORRY_REPLAY_CHUNK` (non-int / `0` / negative / empty) falls back to `30`.
  (`test_replay_chunk_size_env_invalid_falls_back_to_default`.)
- An unset `UNSORRY_REPLAY_CHUNK` is the `30` default.
  (`test_replay_chunk_size_env_unset_is_default`.)
- `gate-a.yml` and `gate-a-full-replay.yml` parse as valid YAML and define their jobs (workflow
  smoke-parse in CI / local `python3 -c 'import yaml; yaml.safe_load(...)'`).
- The incremental scoping functions are untouched (existing `test_parallel_modules.py` incremental
  tests still pass).
