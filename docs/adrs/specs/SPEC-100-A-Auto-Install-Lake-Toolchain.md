# SPEC-100-A: `ensure_lake` — Auto-Install the Lean Build Tool

**Implements:** [ADR-100](../ADR-100-Auto-Install-Lake-Toolchain.md)
**Related:** [ADR-002](../ADR-002-Lean4-Mathlib-Pinned-Release-Tags.md) (toolchain
pin via `lean-toolchain`), [ADR-096](../ADR-096-Phase3-Scoped-Export-Independent-Checker.md)
(the `setup.sh` flow), [ADR-019](../ADR-019-CI-Supply-Chain-Protection.md)
(CODEOWNERS trust surface)

This spec is the living "how" for ADR-100. It defines the shared `ensure_lake`
bootstrap, the call sites that route through it, and the acceptance tests.

## 1. The shared bootstrap (`swarm/lib/ensure_lake.sh`)

A single sourceable file is the **only** authoritative representation of the
"make `lake` available" logic (DRY, protocol §12). It exposes one public function:

```
ensure_lake   # 0 → lake is on PATH (already, or after installing elan); 1 → could not
```

Required behaviour, in order, idempotent and safe to call repeatedly:

1. **PATH hygiene.** Prepend the standard toolchain locations
   (`/opt/homebrew/bin`, `/usr/local/bin`, `~/.elan/bin`) to `PATH` if `~/.elan/bin`
   is not already present. Pure, no I/O — matches the normalisation `agent.sh`
   already did inline.
2. **Fast path.** If `command -v lake` resolves, return `0`. No install, no
   network — so a host that already has elan pays nothing.
3. **Install elan** when `lake` is still absent:
   - If `curl` is unavailable, print an actionable message and return `1`
     (no silent install attempt).
   - Otherwise run the official non-interactive installer:
     `curl --proto '=https' --tlsv1.2 -sSf "$ELAN_INIT_URL" | sh -s -- -y --no-modify-path --default-toolchain none`.
     - `--no-modify-path`: leave the user's shell profile untouched; `PATH` is
       managed in-process (step 1).
     - `--default-toolchain none`: install **no** toolchain at install time; the
       repo's pinned toolchain lands from `lean-toolchain` on the first `lake`
       build (ADR-002). The swarm must never build mathlib from source.
4. **Re-probe.** Re-apply PATH hygiene and return `0` iff `command -v lake` now
   resolves, else `1`.

Configuration / seams:

- `ELAN_INIT_URL` — defaults to `https://elan.lean-lang.org/elan-init.sh`;
  overridable for a private mirror or air-gapped install.
- The single side-effecting step lives in `_ensure_lake_install_elan`, isolated so
  the self-tests stub it without touching the network.
- **All** progress output goes to **stderr**, so a caller that captures stdout
  (e.g. `eval "$(tools/independent_check/setup.sh)"`) is unaffected.

## 2. Call sites (every client-side `lake` consumer routes through `ensure_lake`)

| Script | Before | After |
|--------|--------|-------|
| `swarm/agent.sh` (`--prove-local` startup) | `require_cmd lake` | `ensure_lake \|\| die_config …` |
| `swarm/agent.sh` (`--prove` verify startup) | `[ "$PROVE" -eq 1 ] && require_cmd lake` | `[ "$PROVE" -eq 1 ] && { ensure_lake \|\| die_config …; }` |
| `tools/independent_check/setup.sh` (build `lean4export`) | `lake build` (assumed present) | `ensure_lake \|\| exit 1` then `lake build` |

`agent.sh` sources the bootstrap relative to its own location
(`. "$(dirname "${BASH_SOURCE[0]}")/lib/ensure_lake.sh"`); `setup.sh` sources it via
its computed `$ROOT`. `swarm/run.sh` and `swarm/supervise.sh` invoke no `lake`
directly, so they inherit the behaviour through the subprocesses they launch.

Failure semantics are unchanged from the caller's point of view: a *mandatory*
`lake` (proving) that cannot be installed still aborts with a clear `die_config`;
the *advisory* independent-check `setup.sh` still degrades to run.sh's non-gating
"proceeding WITHOUT it" warning.

## 3. Acceptance tests (`swarm/lib/tests/test_ensure_lake.sh`, hermetic, no network)

Each case runs in an isolated subshell (`HOME`/`PATH` overridden) and stubs
`_ensure_lake_install_elan`:

1. **lake already on PATH** → returns `0`, install **not** attempted.
2. **lake absent, install succeeds** (stub drops a shim into `~/.elan/bin`) →
   returns `0` and `lake` resolves afterward.
3. **lake absent AND curl absent** → returns `1`, install **not** attempted.
4. **lake absent on PATH but present in `~/.elan/bin`** → PATH prepend finds it,
   returns `0`, install **not** attempted.
5. **install runs but `lake` still absent** afterward → returns `1`.

## 4. Quality gates

- `shellcheck` and `bash -n` clean for `swarm/lib/ensure_lake.sh` (added to the
  `agent-lint` workflow alongside the existing swarm scripts).
- `swarm/lib/tests/test_ensure_lake.sh` runs green in `agent-lint` (the same
  hermetic self-test discipline as the other swarm scripts).
- No change to Gate A / Gate B or any trusted gate; CI continues to install elan
  via `leanprover/lean-action`.

## 5. Out of scope

- CI/runner toolchain provisioning (unchanged — `leanprover/lean-action`).
- `ensure_cargo` (the sibling Rust bootstrap in `setup.sh`) is left as-is; this
  spec only adds the Lean equivalent and does not refactor the two together.
- Persisting `~/.elan/bin` to the user's shell profile (deliberately not done —
  `--no-modify-path`).
