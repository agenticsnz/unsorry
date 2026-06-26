# SPEC-107-A: batch verification (K proofs per Gate A run)

Implements: [ADR-107](../ADR-107-Batch-Verification.md) · builds on
[SPEC-105-A](SPEC-105-A-Finalization-Recovery-Janitor.md),
[SPEC-106-A](SPEC-106-A-Difficulty-Aware-Dispatch.md) · Status: Draft · Updated: 2026-06-26

Contract for combining up to `UNSORRY_BATCH_SIZE` independent queued `queued/prove/*` branches into
one `batch/prove/<hash>` PR. Pure logic in `tools/dispatch/batch.py` (unit-tested without git);
`swarm/agent.sh` is the assembly/dispatch shell; `.github/workflows/batch-recovery-janitor.yml` is
the failure-recovery shell. Off by default (`UNSORRY_BATCH_SIZE=1`).

## 1. Selection (pure)

`select_batch(refs, changed_files_of, max_size, *, exclude_goals=())` → the chosen refs:
- `max_size < 2` → `[]` (batching off; caller falls through to singleton dispatch).
- Iterate `refs` **in input order** (already ADR-075/106-ordered). Skip a ref whose goal is in
  `exclude_goals` or already picked, whose `changed_files_of[ref]` is empty/unknown, or whose files
  **intersect** an already-picked ref's files. Otherwise pick it. Stop at `max_size`.
- `goal_of(ref)` parses `[origin/]queued/prove/<goal>/<agent>-<hex>` → `<goal>`.

`batch_branch_name(goals)` = `batch/prove/<first-12-hex of sha256(sorted unique goals)>` —
deterministic, order-independent, idempotent; distinct goal sets never collide on the ref.

## 2. Dedup manifest (pure)

`manifest_block(goals)` → a single `Batch-Goals: <space-joined sorted goals>` line for the PR body.
`parse_manifest(body)` → goals from that line (or `[]`). `open_batch_goals(prs)` unions
`parse_manifest(body)` over every PR whose title starts with `prove-batch(`. The dispatcher adds
these to its dedup set so no singleton opens for an already-batched goal.

## 3. Assembly (`swarm/agent.sh`, gated on `UNSORRY_BATCH_SIZE > 1`)

`dispatch_batch_pass`: fetch queued + main; build the exclude set = `dispatch_open_pr_goals ∪
dispatch_open_batch_goals`; consult `submission_governor_allows` **once** (a batch is one
admission); `tools.dispatch.batch select --max N --exclude-file F` over `queued_branch_refs |
fair_dispatch_order`; require ≥2 picks (else fall through to singletons); ADR-071 `goal_taken_fresh`
re-check each pick; then `assemble_and_dispatch_batch`.

`assemble_and_dispatch_batch`: derive `<branch>`+`<manifest>` via `tools.dispatch.batch meta`; skip
if a PR for `<branch>` already exists (idempotent); `git worktree add -B <branch> … origin/main`;
**`git cherry-pick origin/<b>`** for each constituent (disjoint ADD-only ⇒ never conflicts;
preserves the `prove(<goal>):` subject + author — load-bearing for §6); a cherry-pick conflict
**aborts the whole batch** (cleanup, return non-zero, branches stay queued for singletons);
`tools.gate_b validate` the combined tree (abort on fail); push; `gh pr create` with the manifest in
the body; **`gh pr merge --auto --merge`** (merge commit, NOT squash). Constituent `queued/prove/*`
branches are **never deleted** by assembly (recovery relies on them). `DRY_RUN=1` logs and skips
push/PR.

## 4. Recovery (`batch-recovery-janitor.yml` + pure `recover_action`)

`recover_action(conclusion, jobs)`:
- conclusion empty/`success`/`neutral`/`skipped` → `none` (leave it; auto-merge fires on green).
- conclusion `cancelled` → `rerun`.
- else (`failure`/`timed_out`/…) → `rerun` iff `finalization_recovery.gate_failure_is_cancellation(
  jobs)` (a cancelled leg with no genuine non-cascade failure), else `redispatch`.

Janitor (mirrors `finalization-recovery-janitor.yml`: `workflow_run` on gate-a + cron backstop +
dispatch; `cancel-in-progress: false`; `contents: read`, `pull-requests: write`, `actions: write`;
`REFRESH_TOKEN` or report-only): for each open `prove-batch(` PR, read the latest `gate-a` run's
conclusion + jobs (`gh api …/runs?head_sha=… | … | last`, then `…/runs/<id>/jobs`), pass to
`recover`, and:
- `none` → skip.
- `rerun` → `gh run rerun <id>` + re-arm (`gh pr merge --auto --merge`).
- `redispatch` → for each manifest goal, resolve its `queued/prove/<goal>/*` branch and open a
  **singleton** PR (`prove(<goal>):` title from the branch tip) armed `--auto --squash`; **then**
  close the batch PR. Bounded by a per-run cap. Opening singletons first establishes dedup so the
  set is never re-batched; the bad proof becomes an isolated red singleton (a state already
  tolerated today), the K−1 good ones merge.

## 5. Invariants

- **Off by default / reversible.** `UNSORRY_BATCH_SIZE` unset or `1` ⇒ no batch code runs;
  `dispatch_queue`'s singleton path is byte-for-byte unchanged (the dedup augmentation is gated on
  `> 1`). No goal `.lean` is modified (ADR-018) — the batch adds files only.
- **Conflict-free.** Picked branches have pairwise-disjoint changed files (checked), so the
  combined tree applies cleanly; a collision drops the branch to singleton dispatch.
- **One admission per batch.** The governor (ADR-058) is consulted once; a batch occupies one
  `gate-a` in-flight slot for K proofs.
- **Soundness-neutral (ADR-049, p=1).** Gate A re-verifies every file from scratch — `lake build` +
  nanoda-per-leaf + replay-per-olean; the kernel decides each proof; no proof trusts another; the
  producer is never trusted.
- **Attribution/metrics preserved with no leaderboard change.** `verified_proofs` and provenance are
  file-based (`library/index/*.aisp`); the **merge commit** keeps each `prove(<goal>):` commit
  reachable so `merge_times` (`git log --no-merges`) and `git_add_authors` (`--diff-filter=A --
  library/index`, no `--first-parent`) resolve every batched proof. Asserted by tests.
- **No K−1 stranding.** A genuine batch failure redispatches its constituents singly; recovery is
  bounded and idempotent (deterministic branch name; existing-PR check).

## 6. Conformance

`tools/dispatch/tests/test_batch.py`: `goal_of`; `select_batch` (order-preserving, max cap,
exclude, dup-goal skip, unknown-diff skip, file-collision drop, off-when-max<2); `batch_branch_name`
(deterministic, order-independent, distinct sets distinct); manifest round-trip + absent; 
`open_batch_goals` (batch PRs only); `recover_action` (green/running → none, cancelled → rerun,
cancellation-cascade → rerun, genuine failure/timeout → redispatch). `swarm/agent.sh --self-test`:
`UNSORRY_BATCH_SIZE=1` leaves `dispatch_queue` dispatch counts unchanged (existing dedup/fairness/
taken-midpass tests stay green); batch selection picks disjoint branches and dedups against open
batch goals.

## 7. References

ADR-107, ADR-058 (governor), ADR-075/106 (order), ADR-064/071 (dedup), ADR-005 (auto-merge —
`--merge` for batches), ADR-105 (recovery pattern + `gate_failure_is_cancellation`), ADR-049 (p=1),
ADR-097/063 (per-proof cheap terms), ADR-018 (goal immutability). Roadmap #5683, audit #6751.
