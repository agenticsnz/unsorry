# ADR-069: Launcher Demand-Driven Sourcing Arm

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-069 |
| **Initiative** | problem supply / swarm autonomy |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Proposed |

## Context

ADR-067 / SPEC-067-A shipped the **mechanism** for demand-driven sourcing — the
opt-in `--if-pool-empty` flag on `swarm/sourcing.sh`, which sources only when no
`goals/<slug>.aisp` carries `status≜open` and otherwise no-ops with exit 0. It
deliberately stopped at the mechanism: ADR-067's "Consequences (Negative)" and
SPEC-067-A §7 both record that *wiring the flag into the default run path* — so
that an operator gets empty-pool top-up automatically — was deferred to a
follow-up. This is that follow-up.

The maintainer's vision is concrete and is **not yet met** by v1.23.0: when an
operator runs the one-command launcher (`swarm/run.sh`), the swarm should *by
default* start sourcing the moment it runs out of problems to solve — without the
operator knowing to launch a second `./swarm/sourcing.sh --if-pool-empty` process
or wire a cron. v1.23.0 delivered the lever but left the launcher unchanged
(`run.sh` at v1.23.0 has no mention of sourcing), so the automatic, default-on
behaviour the maintainer expected is absent. The release read as "demand-driven
sourcing shipped" when what shipped was the building block.

The vision has a **second, equally important half**: making auto-source-on-empty
the default must **not** suppress *on-demand* sourcing. If a human (or a scoped
job) explicitly runs `./swarm/sourcing.sh` while the pool still has open
problems, that must still source — the gate is for the *automatic* arm only,
never a global "don't source while the pool is non-empty" policy. ADR-067's
default-off `--if-pool-empty` already preserves this (plain `sourcing.sh` is
unchanged), so the launcher arm must reuse that flag rather than introduce any
new gating on the manual path.

SPEC-067-A §7 framed the deferred bridge as wiring into `supervise.sh` /
`agent.sh` (have the *prover* shell out to sourcing on an empty pool). That
couples a sourcing dependency onto the prove arm's ADR-017 policy and the
~5k-line `agent.sh` — widening the blast radius of every prove change. `run.sh`
already composes the swarm out of independent arms (a ref-only dispatcher loop
plus a worktree-isolated prover, ADR-042); adding sourcing as a **third
independent arm of the launcher** realises the same demand-driven behaviour while
leaving the prove arm, the claim model, and `agent.sh` entirely untouched — a
strictly smaller blast radius than the §7 sketch.

## WH(Y) Decision Statement

**In the context of** a demand-driven sourcing *mechanism* (`sourcing.sh
--if-pool-empty`, ADR-067) that nothing yet invokes automatically, and a
one-command launcher (`swarm/run.sh`, ADR-058) that already runs a background
dispatcher loop alongside a foreground prover but knows nothing about sourcing,

**facing** a maintainer expectation that running `run.sh` *by default* replenish
the backlog exactly when the swarm runs out of problems to solve, under the hard
constraint that making auto-sourcing the default must **not** suppress explicit
on-demand sourcing (`./swarm/sourcing.sh` with no flag must still source with a
non-empty pool), and the preference to leave the prove arm / `agent.sh` / ADR-017
untouched,

**we decided for** adding a **third launcher arm** to `swarm/run.sh`: a
background `sourcer()` loop that invokes `./swarm/sourcing.sh --if-pool-empty` on
a re-poll interval (`UNSORRY_SOURCING_WAIT`, default 300s), sharing the launcher's
`UNSORRY_*` env and torn down with the dispatcher and prover on exit; it is
**on by default** and omitted only when `UNSORRY_SOURCE_ON_EMPTY` is set to a
falsey value (`0`/`false`/`no`/`off`, decided by a pure `source_arm_enabled`
helper mirroring `agent.sh:env_truthy` inverted-with-default-on); the arm reuses
ADR-067's default-off flag verbatim, so it *only adds* the automatic empty-pool
top-up and introduces **no** new gate on the manual `sourcing.sh` path; and the
launcher gains a hermetic `--self-test` (wired into `agent-lint.yml` beside the
existing agent/supervisor/sourcing self-tests) that exercises `source_arm_enabled`
across the truthy/falsey/default matrix,

**and neglected** the SPEC-067-A §7 option of bridging inside `supervise.sh` /
`agent.sh` so the prover shells out to sourcing on its own empty pool (rejected —
it bolts a sourcing dependency onto the ADR-017 prove policy and the ~5k-line
`agent.sh`, widening the blast radius of every prove change; a launcher arm is the
same demand-driven behaviour with the prove arm untouched, and `run.sh` is the
exact surface the maintainer named — "when someone runs run.sh"); making the arm
opt-**in** rather than opt-out (rejected — the vision is explicitly "by default";
default-on with an `UNSORRY_SOURCE_ON_EMPTY=0` escape hatch honours that while
still letting a deployment that sources on a schedule omit the arm); running the
sourcer in its own dedicated git worktree for full isolation (deferred — the
dispatcher is ref-only and the prover is worktree-isolated, so only the sourcer
touches the shared checkout and a *single* sourcer never contends with itself;
its Claude session brackets its own `chore(sourcing)` branch, so co-location is
safe, and worktree-isolating `sourcing.sh` is a larger change to a CODEOWNERS
surface left as a follow-up); and adding any gate to the manual sourcing path
(rejected outright — it would violate the second half of the vision; the arm uses
the default-off flag precisely so `./swarm/sourcing.sh` stays ungated),

**to achieve** the maintainer's end-to-end vision — `./swarm/run.sh` launches a
swarm that proves, dispatches, **and** sources-on-empty out of the box, topping up
the backlog exactly when (and only when) the provers run dry, while an explicit
`./swarm/sourcing.sh` still sources on demand at any pool depth,

**accepting that** the sourcer is a *polling* arm: it re-invokes `sourcing.sh`
every `UNSORRY_SOURCING_WAIT` and each invocation pays `sourcing.sh`'s preflight
(an `origin/main` fetch + a Claude CLI health probe) even on a no-op tick, so the
default-on arm adds a small steady-state cost to a `run.sh` deployment (tunable /
disablable via the two env knobs); that the gate is a per-tick snapshot, so a
sourcing PR opened this tick is not seen as backlog until it merges (ADR-067's
same accepted snapshot semantics); that the launcher arm applies only to the
standalone/forked `run.sh` deployment (a repo with the scheduled `queue-dispatcher`
runs a prover-only setup per ADR-058's run.sh note, and would top up via a
scheduled sourcing job, hence the opt-out); and that the sourcer touches the
shared working-tree checkout — safe for one sourcer beside a ref-only dispatcher
and a worktree-isolated prover, with full worktree isolation left as a follow-up.

## What the arm does (summary; full contract in SPEC-069-A)

1. **Third arm, default-on.** `run.sh` starts `sourcer()` in the background
   alongside the dispatcher, unless `UNSORRY_SOURCE_ON_EMPTY` is falsey.
2. **Demand-driven via the existing flag.** `sourcer()` loops
   `./swarm/sourcing.sh --if-pool-empty`, sleeping `UNSORRY_SOURCING_WAIT`
   (default 300s) between invocations and restarting after a backoff on a
   non-zero exit — mirroring the existing `dispatcher()` loop.
3. **Manual sourcing untouched.** The arm adds only the automatic empty-pool
   top-up; `./swarm/sourcing.sh` (no flag) still sources on demand at any pool
   depth (ADR-067 default-off).
4. **Torn down together.** `cleanup` kills the sourcer with the dispatcher when
   the foreground prover exits or the launcher is interrupted.

## Consequences

- **Positive.** The maintainer's vision is met end-to-end: `./swarm/run.sh`
  proves, dispatches, and sources-on-empty by default, with no second command.
- **Positive.** On-demand sourcing is preserved — the arm reuses ADR-067's
  default-off flag and adds no gate to the manual path.
- **Positive.** The prove arm, claim model, and `agent.sh` / ADR-017 are
  untouched — strictly smaller blast radius than the SPEC-067-A §7 bridge.
- **Positive.** `run.sh` gains a hermetic self-test (the first for this script),
  closing the SPEC-007-A quality-bar gap that it was only shellcheck/`bash -n`'d.
- **Negative.** A default-on polling arm adds steady-state preflight cost (a
  fetch + CLI health probe per tick), tunable via `UNSORRY_SOURCING_WAIT` and
  disablable via `UNSORRY_SOURCE_ON_EMPTY=0`.
- **Negative.** The sourcer touches the shared checkout; full worktree isolation
  of `sourcing.sh` is deferred (safe today for a single sourcer beside a ref-only
  dispatcher and a worktree-isolated prover).
- **Negative.** Inherits ADR-067's snapshot semantics (an in-flight sourcing PR
  is not counted as backlog until it merges) and tree-wide (not claim-aware) pool
  definition.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Launcher Demand-Driven Sourcing Arm spec | Specification | specs/SPEC-069-A-Launcher-Demand-Driven-Sourcing-Arm.md |
| REF-2 | Demand-Driven Sourcing | Decision | ADR-067-Demand-Driven-Sourcing.md |
| REF-3 | Demand-Driven Sourcing spec | Specification | specs/SPEC-067-A-Demand-Driven-Sourcing.md |
| REF-4 | Runner Pool Segmentation & Verification Capacity (governed run.sh) | Decision | ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-5 | Swarm Goal-Sourcing Runner | Decision | ADR-062-Swarm-Goal-Sourcing-Runner.md |
| REF-6 | Swarm Supervisor | Decision | ADR-017-Swarm-Supervisor.md |
| REF-7 | Isolated Agent Worktree | Decision | ADR-042-Isolated-Agent-Worktree.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
