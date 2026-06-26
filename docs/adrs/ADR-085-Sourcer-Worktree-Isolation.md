# ADR-085: Isolate the Sourcer in a Per-Sourcer Worktree (ADR-042 parity)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-085 |
| **Initiative** | unsorry — decentralised swarm infrastructure (sourcing concurrency) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-22 |
| **Status** | Proposed |

## Context

ADR-069 wired demand-driven sourcing into `run.sh` as a default-on arm and
explicitly **deferred** worktree-isolating the sourcer: "running the sourcer in
its own dedicated git worktree for full isolation (deferred — the dispatcher is
ref-only and the prover is worktree-isolated, so only the sourcer touches the
shared checkout and a *single* sourcer never contends with itself … worktree-
isolating `sourcing.sh` is a larger change to a CODEOWNERS surface left as a
follow-up)." [ADR-084](./ADR-084-Demand-Driven-Sourcing-Dedup.md) closed the
over-**sourcing**-PR race (two sourcers no longer both open a `chore(sourcing)`
PR), but it did **not** address shared-working-tree **contention**: the sourcing
cycle's Claude session mutates the checkout it runs in (creates the
`chore(sourcing)` branch, writes `goals/`, commits, opens the PR). So two sourcers
in one clone — or a sourcer racing the dedup TOCTOU and both running a cycle —
stomp on one `.git`/working tree. The prover already solved exactly this for
itself: [ADR-042](./ADR-042-Isolated-Agent-Worktree.md) relocates each agent into
its own detached `origin/main` worktree before any work. This ADR is the deferred
sourcing counterpart, completing the decentralised "anyone runs `run.sh`" safety
story alongside ADR-084.

## WH(Y) Decision Statement

**In the context of** a decentralised swarm where any node may run `run.sh`
(prover + dispatcher + sourcer), with the prover already worktree-isolated
(ADR-042) and the dispatcher ref-only, leaving the sourcer as the one arm that
mutates the shared working-tree checkout,

**facing** the contention ADR-069 deferred: `sourcing.sh` requires `main` checked
out in `.` (`require_main_checkout`) and runs its Claude session there, so two
sourcers in one clone (or the residual ADR-084 dedup TOCTOU letting two cycles
run) corrupt each other's branch/checkout state, and the "safe for a *single*
sourcer" caveat blocks running more than one,

**we decided for** relocating the sourcer into its **own detached `origin/main`
worktree** before any work — mirroring ADR-042: a small self-contained
`ensure_sourcing_worktree` (`git worktree add -q --detach <wt> origin/main` with
the same clone-ownership guard + `git worktree prune`) and
`relocate_into_sourcing_worktree` that re-execs `origin/main`'s `sourcing.sh` from
the worktree (acting on merged code, like the #428 / ADR-039 re-exec); the
worktree path is keyed per sourcer (`$UNSORRY_WORKDIR/sourcing-main-<id>`, id from
`UNSORRY_SOURCER_ID`/`UNSORRY_AGENT_ID`/PID) so concurrent sourcers get distinct
trees; `require_main_checkout` is relaxed to accept the isolated detached-HEAD
state when `UNSORRY_IN_WT=1` (as ADR-042 does for the agent); opt out with
`UNSORRY_NO_ISOLATE=1`,

**and neglected** (a) extracting the prover's `ensure_agent_worktree` /
`relocate_into_agent_worktree` into a shared sourced library — cleaner DRY but a
cross-file refactor of the ~5k-line `agent.sh` CODEOWNERS surface, a far larger
blast radius than mirroring its ~15-line helper locally (DRY-by-pattern, with both
citing ADR-042); (b) ephemeral per-invocation worktrees removed on exit — you
cannot cleanly `git worktree remove` the tree you re-exec'd into, so reuse a
stable per-sourcer worktree exactly as the prover does; and (c) leaving the
sourcer on the shared checkout (ADR-069's single-sourcer status quo — the
limitation this removes),

**to achieve** a sourcer that is safe to run concurrently (multiple sourcers per
clone, and beside the prover/dispatcher) without shared-tree corruption —
finishing what ADR-084 started so sourcing is as concurrency-safe as dispatch,

**accepting that** the relocate re-execs the process (one extra fetch + exec at
startup, and it runs merged `origin/main` code, not the operator's working copy —
intended, per ADR-042/#428); it needs a writable `UNSORRY_WORKDIR`; and that this
is the larger CODEOWNERS change ADR-069 deferred, so **the relocate + Claude-
session-in-worktree path must be validated by a live sourcing cycle before merge**
— the hermetic `--self-test` can cover the pure relocate-guard/path logic but
cannot exercise the actual re-exec or the Claude session, so the implementation
PR is gated on a real-run check, not on unit tests alone.

## Consequences

- **Positive.** Sourcing becomes safe to run concurrently and beside the other
  arms; the "single sourcer" caveat (ADR-069) is lifted; the decentralised model
  is fully safe for all three swarm tasks (prove ADR-042, dispatch ADR-064/071,
  source ADR-084 + this).
- **Negative.** A startup re-exec + fetch; a per-sourcer worktree consumes disk
  under `UNSORRY_WORKDIR`; the implementation can't be fully unit-verified and
  needs a live-run gate before merge.
- **Mirrors** ADR-042 (agent worktree isolation); **completes** ADR-069's deferred
  follow-up; **composes with** ADR-084.

## Implementation status

Specified in [SPEC-085-A](specs/SPEC-085-A-Sourcer-Worktree-Isolation.md). **Not
yet implemented** — the code change to `swarm/sourcing.sh` is staged for an
environment that can run a live sourcing cycle to validate the relocate/re-exec
and the Claude session in the worktree (this sandbox has no Claude CLI and the
self-test is hermetic). Until then this ADR records the decision and design.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Sourcer worktree isolation spec | Specification | specs/SPEC-085-A-Sourcer-Worktree-Isolation.md |
| REF-2 | Isolated Agent Worktree (the pattern mirrored) | Decision | ADR-042-Isolated-Agent-Worktree.md |
| REF-3 | Launcher Demand-Driven Sourcing Arm (deferred this) | Decision | ADR-069-Launcher-Demand-Driven-Sourcing-Arm.md |
| REF-4 | Demand-Driven Sourcing Dedup (the other half) | Decision | ADR-084-Demand-Driven-Sourcing-Dedup.md |
| REF-5 | Re-exec the Agent When the Harness Updates | Decision | ADR-039-Self-Updating-Harness.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-22 |
