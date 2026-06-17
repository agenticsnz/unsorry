# SPEC-046-A: Namespace `.lake` Cache Volume

Implements: [ADR-046](../ADR-046-Gate-A-Namespace-Cache-Volume.md) · Status: Living · Updated: 2026-06-15

## Behaviour

On Namespace runner profiles, Gate A's Lean verifier jobs mount a persistent cache volume at
`${GITHUB_WORKSPACE}/.lake`, so mathlib oleans and the local `UnsorryLibrary`/`UnsorryGoals` build
survive across jobs and runs. The Namespace mount is disabled completely on non-Namespace profiles.
When the Namespace volume reports a cache hit, `lean-action`'s GitHub mathlib cache is disabled
because the volume supplies mathlib. On any non-Namespace profile, or if the Namespace volume
misses/errors, the gate falls back to the existing GitHub caches with no behavioural change.
Gate A also sets `MATHLIB_CACHE_DIR=${{ github.workspace }}/.lake/mathlib-cache` so Lake's mathlib
`.ltar` archive cache is stored inside the mounted `.lake` tree instead of the default
`$HOME/.cache/mathlib`.

## Implementation (`.github/workflows/gate-a.yml`)

- **Per-job volume flags.** The `profiles` step emits role-specific runner labels, then sets
  `<job>_volume=true` iff the label matches `namespace-*`, else `false`; exposed as
  `detect` job outputs such as `prepare_volume`, `audit_volume`, `replay_volume`, and
  `archive_volume`.
- **Mathlib archive cache location.** The workflow-level environment sets
  `MATHLIB_CACHE_DIR: ${{ github.workspace }}/.lake/mathlib-cache`. This makes `lake exe cache get`
  reuse cached `.ltar` archives from the same mounted tree instead of downloading them into the
  runner home directory.
- **Mount step** (in `gate-a-prepare`, `gate-a-audit`, `gate-a-replay`, and `gate-a-archive`, after
  checkout, before the build):
  ```yaml
  - name: Namespace .lake cache volume
    if: needs.detect.outputs.prepare_volume == 'true'
    id: ns_lake_cache
    continue-on-error: true
    uses: namespacelabs/nscloud-cache-action@15799a6b54e5765f85b2aac25b3f0df43ed571c0 # v1.4.3
    with:
      path: ${{ github.workspace }}/.lake
  ```
  The action is keyless (volume-backed bind-mount). The absolute `${{ github.workspace }}/.lake`
  path is required — a relative `.lake` mounts the wrong directory.
- **Namespace diagnostics.** Each job prints the Namespace `cache-hit` output plus compact `.lake`
  size information so a cold/missed volume is visible in logs.
- **GitHub-cache fallback remains live.** The ADR-045 `.lake/build` `actions/cache` step still runs
  on all profiles because it is keyed to the exact commit sha and is the safe same-run handoff from
  prepare to audit/replay. The build `lean-action` step uses
  `use-github-cache: ${{ needs.detect.outputs.prepare_volume != 'true' || steps.ns_lake_cache.outputs.cache-hit != 'true' }}`,
  so GitHub mathlib cache is skipped only for a known Namespace volume hit.
- **Build-skip interaction (ADR-045).** With the `.lake/build` cache step still active on Namespace,
  audit/replay can see `steps.lake_build_cache.outputs.cache-hit == 'true'` for the exact commit sha
  that prepare just saved. Their library build guard (`!= 'true'`) then skips the duplicate
  `lake build UnsorryLibrary --wfail`; on a cache miss the build still runs and self-heals.

## Safety

The volume is advisory build state, never a trust input. `leanchecker` re-checks every olean it
loads against the kernel irrespective of origin; the axiom audit inspects the same oleans; `--wfail`
runs in prepare; and the push-to-`main` full audit + replay re-verify the active library
post-merge. The only failure modes the volume can introduce are a rebuild or a load failure — a red
gate (false negative), never a false PASS.

## Failsafe

- Non-Namespace profile → `volume=false` → mount step skipped, GitHub caches active (today's path).
- Namespace profile, no volume attached / action error → `continue-on-error` keeps the job running;
  mathlib is provisioned through the GitHub cache fallback.
- Namespace profile, cold/missed volume → GitHub caches active; the volume can warm at job cleanup.

## Operator note

Attach a cache volume (~20 GB is ample) to `namespace-profile-unsorry-prepare`, `namespace-profile-unsorry-audit`, and
`namespace-profile-unsorry-replay` so `${GITHUB_WORKSPACE}/.lake` persists. No code change is needed to adopt or to
revert.

## Acceptance criteria

- Per-job volume flags are `true` for `namespace-*` profiles and `false` otherwise.
- `MATHLIB_CACHE_DIR` points under `${{ github.workspace }}/.lake` so the mounted volume contains
  both unpacked oleans and downloaded mathlib `.ltar` archives.
- On a Namespace profile, the mount step runs and `use-github-cache` resolves to `false` only when
  the Namespace cache reports a hit.
- On a non-Namespace profile, the mount step is skipped, `use-github-cache` resolves to `true`, and
  the `.lake/build` cache step runs (ADR-045 behaviour).
- The `.lake/build` cache step runs on Namespace too, so audit/replay can restore prepare's
  commit-exact build and skip duplicate library builds.
- A cold volume run completes within the 45-min prepare/audit and 120-min replay timeouts.
- `gate-a.yml` parses; the four verifier jobs each contain exactly one `nscloud-cache-action` step.
