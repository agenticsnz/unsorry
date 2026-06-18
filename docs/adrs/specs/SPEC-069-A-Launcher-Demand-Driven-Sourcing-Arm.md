# SPEC-069-A: Launcher Demand-Driven Sourcing Arm

Implements: [ADR-069](../ADR-069-Launcher-Demand-Driven-Sourcing-Arm.md) · Status: Living · Updated: 2026-06-17

One deliverable: a third background arm in `swarm/run.sh` that runs
`./swarm/sourcing.sh --if-pool-empty` (SPEC-067-A) on a re-poll interval, so a
single `./swarm/run.sh` proves, dispatches, **and** sources-on-empty by default.
No new runtime files; this extends the launcher and adds its first hermetic
self-test. This spec is the contract for the arm's behaviour, env surface, and
quality bar; everything not restated here is unchanged from SPEC-058-A /
SPEC-067-A.

## 1. CLI surface (delta)

`run.sh` still forwards all positional args to the prover unchanged. It now also
recognises, before launching anything:

| Token | Meaning |
|---|---|
| `--self-test` | Run the hermetic self-test (§4) and exit `0` green / `1` red. Handled before the repo-root guard so it needs no checkout. |
| `-h`, `--help` | Print usage (now naming the sourcer arm and the two env knobs) and exit 0. |

`--self-test` and `--help`/`-h` are launcher tokens consumed by `run.sh`; every
other argument is passed through to `./swarm/supervise.sh --prove "$@"` exactly
as before.

## 2. The sourcer arm

```
sourcer() {
  while :; do
    if ! ./swarm/sourcing.sh --if-pool-empty; then
      log "sourcer exited non-zero; restarting after backoff"
    fi
    sleep "${UNSORRY_SOURCING_WAIT:-300}"
  done
}
```

- **Demand-driven via the existing flag.** Each invocation re-checks the synced
  `main`: `sourcing.sh --if-pool-empty` no-ops with exit 0 while any goal carries
  `status≜open`, and opens exactly one `chore(sourcing):` PR only when the pool
  is empty (SPEC-067-A §3). The wrapper re-polls so the arm fires as the provers
  drain the pool.
- **Resilience.** Mirrors the existing `dispatcher()` loop: a non-zero exit is
  logged and retried after the `sleep`; a clean exit also sleeps then re-polls.
- **Adds only automatic top-up.** The arm passes `--if-pool-empty`, so it never
  gates the manual path — `./swarm/sourcing.sh` (no flag) still sources on demand
  at any pool depth (ADR-069 second-half constraint).

## 3. Default-on with an opt-out — `source_arm_enabled`

```
source_arm_enabled() {
  case "${UNSORRY_SOURCE_ON_EMPTY:-1}" in
    0|false|FALSE|no|NO|off|OFF) return 1 ;;
    *) return 0 ;;
  esac
}
```

- **On by default.** Unset → arm launches (the maintainer's "by default" vision).
- **Opt-out.** `UNSORRY_SOURCE_ON_EMPTY` ∈ {`0`,`false`,`FALSE`,`no`,`NO`,
  `off`,`OFF`} → the arm is omitted (e.g. a deployment topped up by a scheduled
  sourcing job). Any other value enables it (mirrors `agent.sh:env_truthy`,
  inverted with a default-on).
- **Pure.** A function of the environment only — no network, no Claude, no
  subprocess — so §4 exercises it hermetically.

Launch / teardown:

```
dispatcher & dispatch_pid=$!
source_pid=""
if source_arm_enabled; then sourcer & source_pid=$!; fi
cleanup() { kill+pkill dispatch_pid; [ -n "$source_pid" ] && kill+pkill source_pid; }
trap cleanup EXIT INT TERM
./swarm/supervise.sh --prove "$@"      # foreground; its exit runs cleanup
```

When `UNSORRY_SOURCE_ON_EMPTY` is falsey, `source_pid` stays empty and `cleanup`
skips the sourcer kill — `run.sh` is then byte-for-byte the prior two-arm launcher
in behaviour.

## 4. Quality bar (SPEC-007-A, enforced by `agent-lint.yml`)

`run.sh` is already `shellcheck`/`bash -n`'d in `agent-lint`; this adds its first
self-test step. The bar:

- `shellcheck swarm/run.sh` — clean at default severity.
- `bash -n swarm/run.sh` — clean.
- `./swarm/run.sh --self-test` — green. Hermetic test (`run_self_test`):
  - **unset** `UNSORRY_SOURCE_ON_EMPTY` ⇒ `source_arm_enabled` true (default-on).
  - each of `1 true TRUE yes YES on ON garbage` ⇒ true (enabled).
  - each of `0 false FALSE no NO off OFF` ⇒ false (disabled).
  - No network, no Claude, no subprocess; restores the env on exit.
- `agent-lint.yml` gains a `run.sh self-test` step invoking
  `./swarm/run.sh --self-test`, beside the existing agent/supervisor/sourcing
  self-test steps (same `admitted == 'true'` guard).

## 5. Environment (delta)

| Var | Default | Meaning |
|---|---|---|
| `UNSORRY_SOURCE_ON_EMPTY` | on | Launch the sourcer arm; `0`/`false`/`no`/`off` omits it. |
| `UNSORRY_SOURCING_WAIT` | `300` | Seconds the sourcer sleeps between `--if-pool-empty` re-polls. |

`UNSORRY_GOVERNOR_WAIT` (dispatcher re-poll) and all of `sourcing.sh`'s own
`UNSORRY_*` knobs are unchanged.

## 6. Out of scope (deferred)

- **Worktree-isolating the sourcer.** Today only the sourcer touches the shared
  checkout (dispatcher is ref-only; prover is ADR-042 worktree-isolated), so one
  sourcer co-locates safely. Running `sourcing.sh` from a dedicated worktree is a
  larger change to a CODEOWNERS surface, deferred.
- **The prove → source bridge inside `agent.sh` / `supervise.sh`** (SPEC-067-A
  §7). This spec realises demand-driven sourcing at the launcher instead, leaving
  the prove arm untouched; an in-prover bridge remains a separate option.
- **Claim-aware / in-flight-PR-aware pool counting** — inherited from SPEC-067-A
  §7 (the gate is `sourcing.sh`'s tree-wide `open_goal_count`).
- **A scheduled-sourcing workflow** (the GitHub-side complement of the
  `queue-dispatcher`) — out of scope here; the opt-out knob is the hook for a
  deployment that adds one.
