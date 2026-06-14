# SPEC-045-A: Gate A Library Build Cache

Implements: [ADR-045](../ADR-045-Gate-A-Library-Build-Cache.md) · Status: Living · Updated: 2026-06-15

## Behaviour

Each Gate A Lean job (`gate-a-prepare`, `gate-a-audit`, `gate-a-replay`) caches the
repository-local Lake build directory `.lake/build` so `lake build UnsorryLibrary` is
incremental — only changed modules recompile instead of the whole library cold-building. mathlib
is unaffected (it stays on `lean-action`'s separate `use-github-cache` path under
`.lake/packages`).

## Implementation (`.github/workflows/gate-a.yml`)

A step added immediately after `actions/checkout` in all three Lean jobs:

```yaml
- name: Cache local Lake build (.lake/build) — incremental library (ADR-045)
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
  with:
    path: .lake/build
    key: lake-build-${{ runner.os }}-${{ hashFiles('lean-toolchain', 'lake-manifest.json', 'lakefile.toml') }}-${{ github.sha }}
    restore-keys: |
      lake-build-${{ runner.os }}-${{ hashFiles('lean-toolchain', 'lake-manifest.json', 'lakefile.toml') }}-
```

- **Path.** `.lake/build` only — the local `UnsorryLibrary`/`UnsorryGoals` oleans. Not mathlib.
- **Key.** Prefix invalidates on any `lean-toolchain` / `lake-manifest.json` / `lakefile.toml`
  change (→ cold rebuild on an incompatible compiler/deps). The `-${{ github.sha }}` suffix makes
  the key unique per commit.
- **restore-keys.** Drops the sha, so a new commit restores the most recent compatible oleans and
  Lake rebuilds only the delta.

## Two wins from one key scheme

1. **Cross-run incremental.** A new commit misses the exact key, hits the `restore-keys` prefix
   (e.g. `main`'s latest oleans, per GitHub cache scoping), and recompiles only changed modules.
2. **Same-run build-once.** `gate-a-prepare` builds and its post-job saves under
   `…-${{ github.sha }}`. `gate-a-audit`/`gate-a-replay` `need` prepare, so they start after that
   save and get an **exact** key hit → their `lake build UnsorryLibrary` is a near-no-op instead
   of a second/third cold build. (On an exact hit `actions/cache` does not re-save, so there are
   no redundant writes.)

A re-run of a cancelled run hits the exact sha key and skips the build entirely.

## Cold-build timeout headroom

The cache keeps the warm path to ~minutes, but a **cold** build (no restorable `.lake/build` —
the first run on a new cache prefix after a toolchain/mathlib bump, before any push-to-`main`
run has saved a main-scoped cache) still recompiles the whole library (~21 min, growing with the
active module count). `gate_a_prepare` and `gate_a_audit` therefore run with
`timeout-minutes: 45` (not 30, which killed cold builds — #567/#573); `gate_a_replay` stays at
60. The durable bound on cold-build time is ADR-041 archiving (keeping the active set small), not
a larger timeout.

## Soundness invariants (unchanged)

- Lake's content-hash traces recompile any module whose source changed — identical to local
  incremental builds.
- `--wfail` build, axiom audit, and `leanchecker` kernel replay still run; replay kernel-checks
  oleans regardless of whether they were built or restored.
- A push to `main` runs the **full** audit + replay (no BASE_SHA), so every olean that reaches
  `main` is kernel-replayed — a drifted/poisoned cache cannot produce a false PASS.

## Acceptance criteria

- `.github/workflows/gate-a.yml` parses; all three Lean jobs carry the cache step with
  `path: .lake/build` and the `actions/cache` action pinned by commit SHA.
- A second gate-a run on an unchanged tree restores the cache and skips the ~16-21 min cold
  library build (the `Library build — zero-warning bar (--wfail)` step drops to seconds).
- A toolchain/mathlib/lakefile change changes the key prefix → full cold rebuild.
- Gate A's required result (`gate-a`) and its audit/replay verdicts are unchanged by the cache.
