# ADR-059: Fetch Resilience on the Shared Object Store

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-059 |
| **Initiative** | unsorry — swarm operational correctness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-16 |
| **Status** | Accepted |

## Context

ADR-042 relocates each agent into its own **working tree**
(`$UNSORRY_WORKDIR/agent-main-<id>`) and explicitly enables *"several agents per
host"*. Those worktrees — the agent worktree, the `claims` worktree, the launch
dir, and any PR worktree — are all `git worktree add`ed off **one clone**, so
they **share a single object database** (`.git/objects`). ADR-042 isolated the
*index and working files*; it did not isolate the object store.

Every cycle, `sync_repo` runs `git fetch -q origin` (`swarm/agent.sh`) and
`ensure_claims_worktree` runs `git -C "$CLAIMS_WT" fetch -q origin claims`, and
startup runs a third fetch in `relocate_into_agent_worktree`. `git fetch`
transfers a **thin pack** — objects encoded as deltas against base objects the
client is assumed to already hold — and `unpack-objects` resolves those deltas
by reading the base objects out of the local store.

`git fetch` is **not concurrency-safe against a shared object store**. When two
agents on a host fetch into the same `.git/objects` (or a default-threshold
`gc.auto` repack runs underneath a fetch), a base object can be momentarily
unreadable while another fetch's thin pack needs it, producing:

```
error: failed to read delta-pack base object <sha>
fatal: unpack-objects error
```

Issue #983 captured exactly this during a live `--prove` run. The failure is
**transient** — on the affected host the named base object is present and
`git fsck` is clean *after the fact*; the object was simply unreadable for the
instant the unpack needed it. But the code had **no retry**: the first such blip
made `sync_repo` `return 1`, the loop logged "repository sync failed" and exited.
Run bare (not under `supervise.sh`, as in #983) that ends the run outright; run
supervised, `exit 1` is only a short fixed-backoff "cycle failure" — neither path
is the right response to a sub-second race that a second fetch would clear.

This does **not** contradict ADR-016, which rejected in-loop retry: that decision
was scoped to **proof-CLI quota outages measured in hours**, where a sleeping
loop holds a claim and misleads the orchestrator. A git fetch race clears in
milliseconds; bounded retry is the correct tool and the two cases do not overlap.

## WH(Y) Decision Statement

**In the context of** ADR-042 per-agent worktrees that share one object database
and an agent loop that fetches `origin` (and `origin claims`) every cycle,
**facing** issue #983 — a live solving run aborted by a transient
`failed to read delta-pack base object` / `unpack-objects error` from a fetch
racing a sibling fetch or an auto-`gc` on the shared store, against code that had
zero retry around any fetch (`git fetch -q origin || return 1` → loop `exit 1`),
**we decided for** routing every swarm fetch through a single `git_fetch_retry`
helper that (a) runs the fetch with `-c gc.auto=0` so a concurrent repack cannot
prune objects underneath it, (b) retries on any failure with exponential backoff
(pure `fetch_retry_delay` schedule, env-tunable `UNSORRY_FETCH_RETRIES` /
`UNSORRY_FETCH_BACKOFF`), and (c) on exhausting its attempts returns the
infrastructure code **3**, which `sync_repo`/`relocate_into_agent_worktree`
propagate so the main loop exits 3 and `supervise.sh` applies its ADR-016
exponential infra backoff instead of a tight 120 s cycle retry,
**and neglected** isolating the object store per agent (rejected — a separate
clone per agent repays the multi-minute mathlib/`.lake` cache and defeats the
shared-cache point of ADR-042; the race is cheap to *survive*, expensive to
*architect away*), a cross-process `flock` serialising all fetches on a host
(rejected for now — adds a lock file and a new failure mode for a race that a
handful of retries already clears; revisit if retries prove insufficient), and
classifying git error strings to decide retry-ability (rejected — `-q` fetch
output is unstable across git versions; retry-all-then-infra is simpler and
correct: a genuinely-down remote merely exhausts the retries and still lands on
the right exit 3),
**to achieve** a swarm that rides out the ordinary object-store contention of
many agents on one host instead of dying on the first blip — an outage costs
wall-clock and a backoff, never a halted node or a maintainer ping,
**accepting that** a *durable* fetch failure now costs `UNSORRY_FETCH_RETRIES`
attempts plus their backoff before it surfaces (bounded, logged per attempt), and
that `gc.auto=0` on these fetches means loose objects accumulate slightly faster
on the shared store between the gc runs other commands still trigger (acceptable;
the store is a throwaway worktree clone, and unbounded growth is a separate
maintenance concern, not a soundness one).

## Options Considered

### Option 1: Retry helper with `gc.auto=0`, exhaustion → infra exit 3 (Selected)
**Pros:** survives the observed transient race with no architecture change; one
DRY helper covers all three fetch sites; the pure backoff schedule is
hermetically testable; exhaustion lands on the existing ADR-016 exit-3 path so
the supervisor already knows what to do.
**Cons:** a durable outage pays the retry budget before surfacing; `gc.auto=0`
shifts repacking onto other commands.

### Option 2: Per-agent object store (separate clone per agent) (Rejected)
Isolate the store so no fetch ever races another. Rejected: repays the cold
mathlib/`.lake` cache per agent (the exact cost ADR-042 pays once), for a race
that retry already survives.

### Option 3: Host-wide `flock` serialising fetches (Rejected for now)
Serialise all fetches on a host behind one lock. Rejected for now: a lock file
and lock-liveness handling is more machinery — and a new stall mode — than a race
that a few retries clears. Revisit if retries prove insufficient under heavier
per-host agent counts.

## Consequences

- All swarm fetches go through `git_fetch_retry`; no raw `git fetch` of `origin`
  remains in the loop or startup paths.
- `sync_repo` and `relocate_into_agent_worktree` propagate the infra code 3 on
  exhausted fetch retries; the main loop exits 3 and `supervise.sh` backs off
  exponentially (ADR-016 / ADR-017), not on the 120 s cycle-retry path.
- A new `die_infra` mirrors `die_config` for the startup (pre-loop) path.
- Tuning knobs `UNSORRY_FETCH_RETRIES` (default 3) and `UNSORRY_FETCH_BACKOFF`
  (default 2 s base, exponential, capped at 30 s) are documented in `--help`.
- `/swarm/` is code-owned (ADR-019), so the implementing PR carries a code-owner
  review and does not auto-merge on gates alone.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Amends | ADR-042 | Isolated Agent Worktree | Adds object-store-race resilience the worktree isolation did not cover |
| Relates To | ADR-016 | Infrastructure-Failure Guard | Exhausted fetch retries reuse the exit-3 infra signal; the no-retry decision there is scoped to CLI outages, not git races |
| Relates To | ADR-017 | Swarm Supervisor | Exit 3 routes to the supervisor's exponential infra backoff |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-059-A — Fetch resilience on the shared object store | Specification | specs/SPEC-059-A-Fetch-Resilience-On-Shared-Object-Store.md |
| REF-2 | Issue #983 — Glitch during solving run (fatal unpack-objects error) | Incident | https://github.com/agenticsnz/unsorry/issues/983 |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-16 |
| Accepted | unsorry maintainers | 2026-06-16 |
