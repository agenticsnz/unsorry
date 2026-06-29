# SPEC-084-A: Demand-Driven Sourcing Dedup

Implements [ADR-084](../ADR-084-Demand-Driven-Sourcing-Dedup.md). Amends [SPEC-067-A](SPEC-067-A-Demand-Driven-Sourcing.md) / the ADR-069 launcher arm. Mirrors the dispatch dedup of [SPEC-064-A](SPEC-064-A-Goal-Level-Dispatch-Deduplication.md) / [SPEC-071-A](SPEC-071-A-Fresh-Dispatch-Dedup-Recheck.md).

## What changed

`swarm/sourcing.sh`'s `--if-pool-empty` gate now also skips when a `chore(sourcing)` PR is already open, so concurrent sourcers (or one sourcer across `UNSORRY_SOURCING_WAIT` ticks before its PR merges) no longer both open a replenishment PR.

### New functions (`swarm/sourcing.sh`)

- `sourcing_gate_decision(open_n, pr_open)` → `have-work | in-flight | source` — **pure**, no I/O:
  - `open_n > 0` → `have-work` (provers still have goals; don't source)
  - `open_n == 0 && pr_open == 1` → `in-flight` (a `chore(sourcing)` PR is open; replenishment already on the way; skip)
  - `open_n == 0 && pr_open == 0` → `source` (open one `chore(sourcing)` PR)
- `sourcing_pr_in_flight()` → prints `1` / `0` — **best-effort** (ADR-016): `gh pr list --state open --limit 200 --json title` filtered to titles starting `chore(sourcing)`; any `gh` failure or non-numeric result prints `0` (treat as none) so sourcing is never blocked by API health. Uses the **core list API**, not the rate-limited search API (ADR-064/071), and is invoked **only** when `open_n == 0` (≤ one `gh` call per empty-pool tick).

### Gate wiring

In `run_cycle`'s per-cycle `--if-pool-empty` block: compute `open_n`; if `open_n == 0`, set `pr_open=$(sourcing_pr_in_flight)` (else leave `0`, no `gh` call); then `case "$(sourcing_gate_decision "$open_n" "$pr_open")"` → `have-work`/`in-flight` log + `break`; `source` logs and proceeds to the sourcing cycle.

### Unchanged

- Manual `./swarm/sourcing.sh` (no `--if-pool-empty`) is **never** gated — it still sources at any pool depth (ADR-067 default-off flag).
- The slug/statement dedup against `origin/main` within a cycle is unchanged.

## Acceptance criteria / tests

`swarm/sourcing.sh --self-test` (hermetic) — `test_sourcing_gate_decision` asserts:
- `sourcing_gate_decision 3 0 == have-work` and `1 1 == have-work` (open goals beat an open PR)
- `sourcing_gate_decision 0 1 == in-flight`
- `sourcing_gate_decision 0 0 == source`

(`sourcing_pr_in_flight` is the thin network wrapper; its best-effort degradation is by construction — no network in the self-test.)

## Out of scope

- The residual sub-second TOCTOU between the check and the Claude session's `gh pr create` (deferred lock, ADR-084 §neglected; first-merge-wins keeps it sound).
- Sourcer worktree isolation for shared-checkout contention — [ADR-085](../ADR-085-Sourcer-Worktree-Isolation.md) / SPEC-085-A.
