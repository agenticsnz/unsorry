# SPEC-090-A: Periodic Housekeeping Arm

Implements [ADR-090](../ADR-090-Periodic-Housekeeping.md). Adds a recurring model→Pokémon naming arm to `swarm/run.sh`, mirroring the `dispatcher()`/`sourcer()` loops ([ADR-058](../ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md)/[ADR-069](../ADR-069-Launcher-Demand-Driven-Sourcing-Arm.md)) and reusing the worktree-isolation pattern of [SPEC-085-A](SPEC-085-A-Sourcer-Worktree-Isolation.md). Closes the startup-only-gate gap from [ADR-083](../ADR-083-Model-Pokemon-Registry-And-Operational-Tasks.md).

> **Status: design (Proposed).** Touches the CODEOWNERS-gated `/swarm/` surface and needs a live swarm run to verify; the code change lands in a follow-up PR with a human code-owner review — see §Verification.

## Goal

A running `run.sh` re-checks the model distribution on an interval and names any model that has appeared since startup, without a launcher restart or a change to `run.sh` itself.

## Behaviour

- The startup blocking gate (`run.sh` → `housekeeping.sh` before the proving arms) is **unchanged**.
- After the arms start, a background **housekeeper** loop runs `housekeeping.sh` every `UNSORRY_HOUSEKEEPING_WAIT` seconds. Each pass `sync`s to clean `origin/main`, lists `unassigned`, and drains any new model (one PR each, settled before the next — existing ADR-083 logic). A pass with nothing unassigned exits 0 quickly.
- Enabled exactly when the gate is: `UNSORRY_HOUSEKEEPING=1` (default). `=0` disables gate **and** arm.
- **Fork mode** (`is_fork_run`): prover only — no housekeeper (a fork cannot open the upstream registry PRs).

## Changes to `swarm/run.sh`

1. **`housekeeper()` loop** (mirrors `sourcer()`):
   ```sh
   housekeeper() {
     while :; do
       if ! ./swarm/housekeeping.sh; then
         log "housekeeper exited non-zero; retrying after backoff"
       fi
       sleep "${UNSORRY_HOUSEKEEPING_WAIT:-900}"
     done
   }
   ```
2. **Launch** it as a background arm next to `dispatcher`/`sourcer`, gated on `UNSORRY_HOUSEKEEPING` (reuse the existing `=1` default check), capturing `housekeeper_pid`.
3. **Teardown**: extend `cleanup()` to `kill`/`pkill -P` `housekeeper_pid` alongside the others; include it in the startup `log` line.
4. **No new arm in fork mode** — the housekeeper is started only on the non-fork path (same place the dispatcher/sourcer start), so the existing fork `exec ... --prove` short-circuit already excludes it.

## Worktree isolation (required)

`housekeeping.sh` mutates the checkout (`sync_base`, `goto_clean_base`, `git checkout -B`), and the shared `.` checkout is also touched by the sourcer — so the periodic arm must not run in `.`. Two options; **(a) preferred**:

- **(a)** Add a `relocate_into_housekeeping_worktree()` to `housekeeping.sh` mirroring SPEC-085-A's `relocate_into_sourcing_worktree` (detached `origin/main` worktree under `${UNSORRY_WORKDIR:-$HOME/.unsorry/work}/housekeeping-main-$id`, re-exec via `UNSORRY_IN_WT`), called at the top of `main()` and skipped under `--self-test`. The **startup** invocation (before any arm, clean tree) can opt out with the same `UNSORRY_NO_ISOLATE` sentinel so the first gate keeps running in place.
- **(b)** Have the `run.sh` arm `cd` into a dedicated `git worktree add --detach` before invoking `housekeeping.sh`. Keeps `housekeeping.sh` untouched but duplicates worktree plumbing in `run.sh`. Rejected unless (a) proves awkward.

## Env knobs

- `UNSORRY_HOUSEKEEPING_WAIT` — housekeeper re-poll interval, default **900** (longer than the 300s dispatcher/sourcer cadence: new models are rare and each pass may spend a research call).
- `UNSORRY_HOUSEKEEPING` (reused) — `0` disables the gate and the arm.
- `UNSORRY_NO_ISOLATE` / `UNSORRY_WORKDIR` / `UNSORRY_IN_WT` (reused from SPEC-085-A).

## Tests (`run.sh --self-test`, hermetic)

- A pure `housekeeper_arm_enabled()` mirrors `source_arm_enabled`: default-on; off for `0/false/no/off`; on otherwise. Self-test table-drives it like the existing arm gate.
- Assert fork mode never starts the housekeeper (the fork branch `exec`s before the arm block — covered by the existing fork short-circuit; add a self-test note).
- `housekeeping.sh --self-test` keeps passing (the relocate helper is pure-checked like sourcing's).

## Verification (live)

On a non-fork node with a deliberately-unnamed model in the distribution: start `run.sh`, confirm the startup gate names the backlog, then add/await a new distribution row and confirm the housekeeper names it within one interval and opens exactly one labelled PR — with the prover/dispatcher/sourcer arms unaffected (no working-tree contention, courtesy of the isolated worktree).

## Out of scope

- Changing `housekeeping.sh`'s naming/validation logic (ADR-083 stands).
- Server-side (Actions) naming — explicitly rejected in ADR-090.
