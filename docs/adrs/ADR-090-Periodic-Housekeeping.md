# ADR-090: Periodic Housekeeping — Naming as a Recurring Operational Task

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-090 |
| **Initiative** | unsorry — keeping the model→Pokémon registry complete as the distribution grows |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-23 |
| **Status** | Proposed |

## Context

[ADR-083](ADR-083-Model-Pokemon-Registry-And-Operational-Tasks.md) made model→Pokémon naming
the swarm's first **operational task**: `swarm/housekeeping.sh` is the first thing `run.sh` runs,
and it **blocks** — no proving/dispatch/sourcing starts until every model in the leaderboard
distribution (`docs/metrics/leaderboard-ui.json` → `models[]`) has a Pokémon in
`docs/metrics/model-registry.json`.

That guarantee is enforced **only at launcher startup**. The model distribution is *dynamic* — a
new `provider/model` cohort can appear at any time (a new provider, a new model, or a newly-split
deterministic-tactic label). A long-lived `run.sh`:

1. clears housekeeping once, then drops into the **foreground prover loop**
   (`supervise.sh --prove`), which never returns to housekeeping; and
2. re-execs **only when `swarm/run.sh`'s own blob changes on `main`**
   (`self_update_to_latest` → `run_harness_stale`). The constant stream of `prove(...)` merges
   advances `main` but leaves the launcher blob unchanged, so there is no re-exec and no second
   housekeeping pass.

The scheduled `queue-dispatcher` backstop does no naming. So a cohort that first appears **after**
a node has started proving stays unnamed indefinitely on that node.

**Observed (2026-06-23):** `lean / ring` (the deterministic Lean `ring`-tactic class, 391 proofs)
first entered the distribution on 23 Jun (`54b811e2`), one day after the 22 Jun naming batch that
named the other 13 models (and after `swarm/run.sh`/`housekeeping.sh` themselves last changed, 22
Jun). Running nodes never re-ran housekeeping, so `lean / ring` is the sole entry on
`python3 -m tools.model_registry unassigned`, with no in-flight PR. The ADR-083 promise — "every
model that appears in the distribution is assigned a Pokémon" — silently degraded from an
invariant to a startup snapshot.

## WH(Y) Decision Statement

**In the context of** model→Pokémon naming being a *startup-only* gate ([ADR-083](ADR-083-Model-Pokemon-Registry-And-Operational-Tasks.md)) over a *dynamic* model distribution,

**facing** new cohorts that appear mid-run never being named until a launcher restart or a change
to `swarm/run.sh` itself (observed: `lean / ring`, unnamed for a day on running nodes),

**we decided for** making housekeeping a **recurring** operational task — a fourth `run.sh` arm
that re-invokes `swarm/housekeeping.sh` on an interval, mirroring the demand-driven dispatcher and
sourcer loops, default-on whenever the startup gate is on and excluded in fork mode,

**and neglected** (a) the status quo of relying on `run.sh` re-exec/restart — leaves an
unbounded-in-time window where a model is unnamed and depends on an unrelated launcher edit;
(b) a scheduled GitHub Actions naming job — the naming agent is a local `claude -p` with
`WebSearch`/`WebFetch`, so it would need an Anthropic key and tool access in CI, a trust/secret
surface we deliberately keep out of Actions; (c) triggering naming from the leaderboard-refresh
job — couples two subsystems and still leaves locally-run nodes dependent on a server job,

**to achieve** the ADR-083 completeness guarantee **continuously** — a new model is named within
one interval, with no restart — while reusing the already-idempotent, concurrency-safe
`housekeeping.sh` drain loop unchanged,

**accepting that** the arm spends a periodic `tools.model_registry unassigned` check (cheap; it
no-ops in well under a second when nothing is unassigned) and, only when a genuinely new model
appears, one `claude -p` research call — and that, like the sourcer ([ADR-085](ADR-085-Sourcer-Worktree-Isolation.md)), it must run in an isolated worktree because it
mutates the checkout.

## Decision

- Add a **housekeeper arm** to `run.sh`: a background loop that runs `swarm/housekeeping.sh` then
  sleeps `UNSORRY_HOUSEKEEPING_WAIT` (default 900s), restarting after a backoff on non-zero exit —
  the same shape as `dispatcher()` / `sourcer()`.
- The arm is enabled exactly when the existing startup gate is (`UNSORRY_HOUSEKEEPING=1`, the
  default); `UNSORRY_HOUSEKEEPING=0` disables both the gate and the arm.
- **Fork mode** ([ADR-068](ADR-068-Fork-Native-Contribution-Mode.md)) runs the prover only — no housekeeper (a
  fork cannot open the upstream's registry PRs), exactly as it excludes the dispatcher/sourcer.
- The periodic housekeeper runs in an **isolated worktree** (mirror [ADR-085](ADR-085-Sourcer-Worktree-Isolation.md) / SPEC-085-A), since `housekeeping.sh` mutates the
  working tree and the shared checkout is also touched by the sourcer.
- The **startup blocking gate is unchanged** — the first pass still drains all unnamed models
  before proving; the arm only adds the continuous re-check thereafter.
- `housekeeping.sh` behaviour is **unchanged** — it is already a settle-each-PR drain loop that
  no-ops cleanly when nothing is unassigned; `run.sh` simply invokes it on a schedule.

Implementation: **SPEC-090-A**. Tracking issue: filed on `agenticsnz/unsorry` (companion to this ADR).

## Consequences

- New models are named within one `UNSORRY_HOUSEKEEPING_WAIT` interval without a launcher
  restart; the ADR-083 guarantee becomes continuous, not a startup snapshot.
- One more background arm and its env knob; bounded periodic cost (an `unassigned` check, plus a
  research call only when a new model actually appears).
- Requires worktree isolation for the arm — a small amount of new plumbing in `run.sh`/
  `housekeeping.sh` (reuses the ADR-085 pattern).
- `/swarm/` is CODEOWNERS-gated, so the implementing PR carries a human code-owner review
  (ADR-019) — appropriate for launcher behaviour.
