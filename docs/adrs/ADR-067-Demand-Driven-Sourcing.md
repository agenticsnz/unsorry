# ADR-067: Demand-Driven Sourcing

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-067 |
| **Initiative** | problem supply / swarm autonomy |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Accepted |

## Context

ADR-062 / SPEC-062-A shipped `swarm/sourcing.sh`, the bounded runner that fires
up Claude to source new open goals and open one `chore(sourcing):` PR per cycle.
It is unconditional: every invocation opens a PR regardless of how full the
backlog already is.

The *prove* arm has the opposite shape. `swarm/agent.sh --prove` loops until the
claimable pool is empty and then exits 0; `swarm/supervise.sh` reads that as
"nothing to do" and (for an unscoped run) stops — "the swarm has run out of
problems to solve" (ADR-017). ADR-044 already taught the prove arm not to go idle
while *parked* work remains, but when the backlog is genuinely drained, the prove
side simply stops.

Nothing bridges the two. When provers run the pool dry, a human must notice and
launch sourcing by hand; conversely, running `sourcing.sh` while hundreds of open
goals are still queued oversupplies the backlog faster than provers clear it. The
maintainer asked to close this loop: *update `sourcing.sh` so that when there are
no problems to solve, it kicks off a sourcing run instead* — make sourcing
**demand-driven**, the complement of the prove arm's empty-pool stop.

Two constraints shape the design. The change must stay inside `sourcing.sh` (a
`CODEOWNERS`-owned surface) and must not perturb the prove arm, the claim model
(ADR-053; sourcing has no claim branch, ADR-060/ADR-062), or the bounded-run
discipline (ADR-062). And it should answer the simple question "is any goal still
open?" using the marker the codebase already trusts — the `status≜` field that
`supervise.sh:scope_closed` reads (a merged proof rewrites `status≜open` →
`status≜proved`) — rather than re-deriving "proved" from the library index or
pulling in the claim-aware claimability machinery the prove arm uses.

## WH(Y) Decision Statement

**In the context of** an unconditional sourcing runner (`sourcing.sh`, ADR-062)
and a prove arm that stops when the claimable pool is empty (`agent.sh` /
`supervise.sh`, ADR-017), with no bridge that sources exactly when the backlog
runs dry,

**facing** a maintainer request to make sourcing demand-driven — source only
when there are no problems left to solve — under the constraints that the change
stay inside `sourcing.sh`, leave the prove arm / claim model / bounded-run
discipline untouched, preserve every existing invocation's behaviour, and reuse
the existing `status≜open` marker rather than re-deriving "proved" or importing
claim plumbing,

**we decided for** a new **opt-in `--if-pool-empty` flag** on `sourcing.sh` that,
before each cycle, counts goals carrying `status≜open` on the freshly-synced
`main` via a pure `open_goal_count` helper (reading the same `status≜` field
`supervise.sh:scope_closed` reads — DRY, not a fresh "proved" computation); if
any goal is open it logs and **no-ops with exit 0** (no Claude call, no PR), and
only when the count is **zero** does it run the normal bounded sourcing cycle
("kick off a sourcing run instead"); the gate is re-evaluated at the top of every
cycle, so a multi-cycle run also stops the instant the backlog refills (a prior
cycle's PR merged, or a prover queued new work); and it is **default-off**, so
every existing `sourcing.sh` invocation is byte-for-byte unchanged,

**and neglected** making the gate the default / always-on (rejected — it would
silently change every existing invocation and the bounded `--cycles` / `--theme`
workflows; opt-in preserves backward compatibility and mirrors ADR-062's
"bounded-by-default, explicit opt-in for the bigger behaviour" caution); putting
the bridge in `supervise.sh` / `agent.sh` so the prover shells out to sourcing on
an empty pool (rejected for this change — it bolts a sourcing dependency onto the
prove arm's ADR-017 policy and the 5k-line `agent.sh`, widening the blast radius
of every prove change; the request named `sourcing.sh`, and a self-contained flag
is invoked identically from a supervisor or cron, so the prover-side wiring is a
clean follow-up once the flag exists); reusing `agent.sh`'s `prove-candidates` /
`py_helper` to define "the pool" (rejected — that helper needs the claims dir and
agent id and encodes claim-aware claimability (TTL, caps), whereas demand-driven
sourcing wants the simpler, claim-independent "is any goal still open?"; pulling
claim plumbing into `sourcing.sh` would duplicate ADR-053 machinery the runner
deliberately has none of); and counting `status≜blocked` goals as problems
(rejected — a blocked parent is parked on its sub-lemmas, which are themselves
`status≜open` and already counted; `status≜open` is the precise "claimable
backlog" signal and matches `scope_closed`'s status semantics),

**to achieve** a one-command, supervise-compatible way to run sourcing exactly
when the swarm runs out of problems to solve — the complement of the prove arm's
empty-pool stop — that keeps ADR-060's difficulty bar, ADR-062's bounded-run and
scoped-allowlist guardrails, and the prove arm itself untouched,

**accepting that** `open_goal_count` duplicates the one-line `status≜` read
already in `supervise.sh` rather than extracting a shared helper (the same
deliberate small-duplication trade-off ADR-062 accepted for its pure helpers,
deferred to a future `swarm/lib.sh`); that the gate reads the working-tree
`goals/` snapshot (synced to `origin/main` by the existing preflight fetch in a
live run; the local tree under `--dry-run`), so a sourcing PR opened this cycle
but not yet merged does not register as backlog until it lands — fine, because
the operator re-invokes and the next tick sees it; and that "pool empty" is
defined as zero `status≜open` goals, so a tree of only `proved` + `blocked`
goals (a transient the ADR-009 unblock sweep is about to reopen) reads as empty
for one tick.

## What the flag does (summary; full contract in SPEC-067-A)

1. **Opt-in.** Without `--if-pool-empty`, `sourcing.sh` behaves exactly as
   ADR-062 specified. The flag is parsed into `IF_POOL_EMPTY` and defaults off.
2. **Gate per cycle.** At the top of each cycle (after the ADR-059 preflight
   fetch + `require_main_matches_origin` have synced `main`), `open_goal_count
   goals` counts `goals/<slug>.aisp` records with a `status≜open` line.
3. **Empty ⇒ source; non-empty ⇒ no-op.** Zero open goals → run the normal
   bounded cycle. One or more → log `N open goal(s) still to solve` and stop the
   loop with exit 0 (no Claude call, no PR).
4. **Exit codes unchanged.** Still 0 ok/nothing-to-do · 1 cycle fail · 2 config ·
   3 infra, so `supervise.sh` wraps it unchanged (SPEC-062-A §5).

## Consequences

- **Positive.** Sourcing becomes demand-driven: a supervisor or cron can keep
  `./swarm/sourcing.sh --if-pool-empty` running, and it replenishes the backlog
  exactly when, and only when, provers run dry — never oversupplying.
- **Positive.** Opt-in + default-off means zero change to existing sourcing
  invocations and the bounded `--cycles` / `--theme` workflows.
- **Positive.** Reuses the existing `status≜open` marker (DRY with
  `supervise.sh`); no new claim, proved-index, or worktree plumbing, and the
  exit-code contract is untouched.
- **Negative.** The gate is a snapshot of `goals/` at cycle start; an in-flight
  sourcing PR is not visible as backlog until it merges (mitigated by
  re-invocation and the per-cycle re-check).
- **Negative.** It counts open goals tree-wide, not claim-aware viability; a goal
  claimed-but-unproved still reads as a problem to solve (intended — it *is*
  unsolved).
- **Negative.** The prove → source bridge in the supervisor (have the prover
  invoke sourcing on an empty pool) is deferred to a follow-up; this ADR delivers
  the mechanism the bridge would call.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Demand-Driven Sourcing spec | Specification | specs/SPEC-067-A-Demand-Driven-Sourcing.md |
| REF-2 | Swarm Goal-Sourcing Runner | Decision | ADR-062-Swarm-Goal-Sourcing-Runner.md |
| REF-3 | Swarm goal-sourcing runner spec | Specification | specs/SPEC-062-A-Swarm-Goal-Sourcing-Runner.md |
| REF-4 | Contributor-Facing Goal-Sourcing Skill | Decision | ADR-060-Contributor-Goal-Sourcing-Skill.md |
| REF-5 | Swarm Supervisor | Decision | ADR-017-Swarm-Supervisor.md |
| REF-6 | Idle Recovery Of Parked Goals | Decision | ADR-044-Idle-Recovery-Of-Parked-Goals.md |
| REF-7 | Agent Loop Script | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |
| REF-8 | Demand-driven sourcing request | Issue | maintainer follow-up (this change) |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
| Accepted (implemented — --if-pool-empty sourcing, #2112) | unsorry maintainers | 2026-06-19 |
