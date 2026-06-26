# SPEC-105-A: finalization-recovery janitor

Implements: [ADR-105](../ADR-105-Finalization-Recovery-Janitor.md) · Status: Draft ·
Updated: 2026-06-26

Contract for recovering stranded *mergeable* prove PRs in two bounded passes. Selection logic is
pure (`tools/repo/finalization_recovery.py`), unit-tested without `gh`; the workflow is the thin
I/O shell.

## 1. Pass A — arm un-enrolled same-repo prove PRs

`should_arm(pr)` is True iff ALL hold:
- `isCrossRepository` is false (cross-repo is owned by `fork-automerge-enabler`, ADR-068);
- `isDraft` is false;
- `autoMergeRequest` is null (not already armed);
- `title` matches `^prove\([^)]+\):` (ADR-026);
- `mergeStateStatus` ≠ `DIRTY` (arming a conflict is futile);
- `within_allow(files)` — ≥1 changed path and **every** path under `library/`, `goals/`, or
  `proof-runs/` (fail-closed: an empty/absent file list is NOT admissible).

`select_arm(prs, limit)` returns admissible PR numbers, oldest-number first, capped at `limit`
(default 30). The shell arms each with `gh pr merge --auto --squash`; a PR already `CLEAN`
rejects `--auto` ("in clean status"), so it falls through to a direct `--squash`.

## 2. Pass B — re-run cancellation-failed gates

A candidate is an open, non-draft, `MERGEABLE` PR whose latest `gate-a` run concluded `failure`.
`gate_failure_is_cancellation(jobs)` decides recoverability:
- True iff **≥1 job** has conclusion `cancelled` **and no NON-cascade job** has conclusion
  `failure`.
- A *cascade* job is one whose name matches `-cover$` or is exactly `gate-a` (it merely reflects a
  cancelled leg). Any other `failure` — a leaf check (`gate-a-nanoda`, `gate-a-replay (N)`, the
  library build) or `admission` (the per-author cap policy) — is **genuine** ⇒ not recoverable.

For a recoverable run the shell `gh run rerun`s it and arms auto-merge. Capped at 15 reruns/pass.

## 3. Invariants

- **No gate is bypassed.** Pass A only *arms*; GitHub enforces required checks before merging.
  Pass B only *re-runs* Gate A — it cannot admit a bad proof (a real failure re-fails).
- **Proof-only scope.** Arming is restricted to diffs entirely within the proof allow-paths; a PR
  touching a gate/harness/workflow is never armed by this automation (also CODEOWNERS-guarded).
- **Conservative + bounded.** Both passes act only on a positive recoverable signal and cap per
  run; nothing loops or fans out.
- **Fail-closed on auth.** Without `REFRESH_TOKEN` the workflow runs report-only (a merge/rerun
  under the default `GITHUB_TOKEN` would not attribute to a real actor / fire downstream
  workflows).
- **Firehose-resilient.** `cancel-in-progress: false` coalesces the frequent `workflow_run`
  triggers (one running + one pending) so the sweep completes instead of being cancelled.

## 4. Conformance (tools/repo/tests/test_finalization_recovery.py)

`should_arm`: arms plain same-repo prove PR; skips cross-repo / armed / draft / non-prove-title /
DIRTY / out-of-allow-paths / unseen-diff. `gate_failure_is_cancellation`: True on audit-cancel +
cover-cascade and prepare-cancel + replay-cover-cascade; False on genuine leaf failure, admission
failure, no-cancellation, and all-success. `select_arm`: ordering + cap. CLI: `arm`,
`is-cancellation`, usage error.

## 5. References

ADR-105, ADR-068/SPEC-068-A (fork auto-merge), ADR-005, ADR-026, ADR-019, ADR-058. Sibling tool
`tools/repo/dropped_gate_prs.py` (the zero-run case this complements).
