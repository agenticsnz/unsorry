# SPEC-085-A: Sourcer Worktree Isolation

Implements [ADR-085](../ADR-085-Sourcer-Worktree-Isolation.md). Mirrors [SPEC-042-A](SPEC-042-A-Isolated-Agent-Worktree.md) (agent worktree isolation) for `swarm/sourcing.sh`. Composes with [SPEC-084-A](SPEC-084-A-Demand-Driven-Sourcing-Dedup.md).

> **Status: design (Proposed).** The code change is staged for a live-run-capable environment — see §Verification.

## Goal

Run each sourcing cycle in a dedicated detached-`origin/main` git worktree instead of the shared `.` checkout, so multiple sourcers (and a sourcer beside the prover/dispatcher) never contend on one working tree.

## Functions to add (`swarm/sourcing.sh`)

Mirror the prover's helpers (ADR-042) as small, self-contained copies (DRY-by-pattern; both cite ADR-042):

- `ensure_sourcing_worktree(wt)` — if `wt` exists, assert it belongs to this clone (`git -C "$wt" rev-parse --path-format=absolute --git-common-dir` equals ours) else `die_config`; otherwise `git worktree prune` then `git worktree add -q --detach "$wt" origin/main`. Identical shape to `agent.sh:ensure_agent_worktree`.
- `relocate_into_sourcing_worktree()` —
  1. return early if `UNSORRY_IN_WT=1` (already relocated) or `UNSORRY_NO_ISOLATE=1` (opt-out);
  2. `require_unsorry_origin`; `git_fetch_retry . origin main` (ADR-059) or `die_infra`;
  3. `workdir="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"`; `mkdir -p`;
  4. `id="${UNSORRY_SOURCER_ID:-${UNSORRY_AGENT_ID:-$$}}"`; `wt="${UNSORRY_SOURCING_WORKTREE:-$workdir/sourcing-main-$id}"`;
  5. `ensure_sourcing_worktree "$wt"`; `cd "$wt"`; `export UNSORRY_IN_WT=1`;
  6. `exec "$wt/swarm/sourcing.sh" "${_ORIG_ARGV[@]}"` (re-exec merged code, like #428/ADR-039).
- Capture `_ORIG_ARGV=("$@")` at the top of `main()` (the prover keeps the original argv for the re-exec).

## Changes to existing functions

- `require_main_checkout`: when `UNSORRY_IN_WT=1`, accept a detached HEAD whose commit equals `origin/main` (the isolated worktree is a detached checkout, exactly as `agent.sh` tolerates under ADR-042 at agent.sh:1430) instead of requiring the branch literally be `main`.
- `main()`: call `relocate_into_sourcing_worktree` **before** `require_repo_root`/cycle preflight runs against the tree — i.e. before any git-mutating work, and skipped under `--self-test`/`--dry-run` (no relocate needed for a hermetic or print-only run).

## Env knobs (new / reused)

- `UNSORRY_NO_ISOLATE=1` — run in place (no worktree), for debugging or a single-sourcer deployment.
- `UNSORRY_SOURCING_WORKTREE` — override the worktree path.
- `UNSORRY_SOURCER_ID` — distinguish concurrent sourcers in one clone (falls back to `UNSORRY_AGENT_ID`, then PID).
- `UNSORRY_WORKDIR` (reused, default `$HOME/.unsorry/work`), `UNSORRY_IN_WT` (internal relocate sentinel).

## Tests

- **Hermetic self-test (`--self-test`)** — add pure tests for the relocate guard: a `sourcing_relocate_decision(in_wt, no_isolate)` → `relocate | skip` helper (skip when `UNSORRY_IN_WT=1` or `UNSORRY_NO_ISOLATE=1`, else relocate) and the worktree-path derivation, exercised across the env matrix. These lock the pure logic without a network or a real worktree.
- **Live verification (merge gate, not unit-testable here):** on a real checkout, `UNSORRY_WORKDIR=$(mktemp -d) ./swarm/sourcing.sh --if-pool-empty --once` must (a) create `…/sourcing-main-<id>` as a detached `origin/main` worktree, (b) run the cycle there with the launch dir untouched, (c) open exactly one `chore(sourcing)` PR from the worktree, and (d) a second concurrent sourcer (distinct `UNSORRY_SOURCER_ID`) must not corrupt the first's tree. This is the gate ADR-085 requires before merge.

## Out of scope

Extracting a shared worktree library from `agent.sh` (cross-file refactor of a CODEOWNERS surface); per-invocation worktree teardown (stable reuse mirrors the prover).
