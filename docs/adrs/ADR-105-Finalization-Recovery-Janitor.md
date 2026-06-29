# ADR-105: Recover stranded mergeable prove PRs (auto-merge enrolment backstop + cancellation-failed gate recovery)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-105 |
| **Initiative** | throughput / finalization resilience |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-26 |
| **Status** | Proposed |

## Context

A live audit (2026-06-26) found the swarm's merge ceiling is **not** Gate A/B *compute* —
the gates run with slack (≈8 in flight vs a ≈20 cap). The bottleneck is **finalization**:
completed, mergeable work strands *after* the checks. Of 38 open PRs, ~24 were stuck 12–113 h
in two recurring patterns:

1. **Un-enrolled auto-merge.** ~12 PRs were `CLEAN` + mergeable + gates green but had auto-merge
   **OFF** — the swarm's enrol-at-creation step had failed (a known `REFRESH_TOKEN` PR-write
   gap), so the PR sat unmerged forever. `fork_automerge.py` / `fork-automerge-enabler` arm
   **cross-repo** PRs only (ADR-068); **same-repo** swarm PRs that miss enrolment have **no
   backstop**.
2. **Cancellation-failed gate.** ~6 PRs were `BLOCKED` with `gate-a` = FAILURE, but the failure
   was a **cascade of a CANCELLED sub-job** — the concurrency `cancel-in-progress` killed an
   audit/replay leg, and the cover job reported failure. The proof is fine (`mergeable`), but
   `dropped_gate_prs.py` correctly treats any failed/cancelled gate as a real block and leaves
   it, and nothing else re-runs it. With no new commit, it never recovers.

These are *recoverable mergeable* PRs — the work is done; only the plumbing stalled. The existing
janitor suite (dropped-gate / stale-failed / superseded / stale-branch) doesn't cover either case.

## Decision

**Add a `finalization-recovery-janitor` that recovers stranded mergeable prove PRs in two
conservative, bounded passes**, driven by `tools.repo.finalization_recovery` (pure, unit-tested):

1. **ARM.** For each open, non-draft, non-cross-repo **prove** PR (ADR-026 title) whose diff
   touches **only** the proof allow-paths (`library/`, `goals/`, `proof-runs/`), is not already
   armed, and is not `DIRTY`: arm auto-merge (or, if already `CLEAN`, squash-merge directly).
   GitHub still blocks the merge until Gate A/B are green — this only *arms* it (ADR-005).
2. **RERUN.** For each open, non-draft, **mergeable** PR whose latest `gate-a` run is `failure`:
   re-run that run **iff** the failure is purely a cancellation cascade — `gate_failure_is_
   cancellation(jobs)` = (≥1 job `cancelled`) AND (no NON-cascade job `failure`). A genuine leaf
   failure (a bad proof) or an `admission` policy failure (the per-author cap) is **left alone**.

Posture mirrors `dropped-gate-janitor`: `workflow_run` on `gate-a` is the primary trigger (every
completion rescans all open PRs), `cancel-in-progress: false` so the firehose **coalesces**
instead of cancelling the sweep, cron is a backstop, and it runs as `REFRESH_TOKEN` so the
merge/rerun attribute to a real actor (degrades to report-only without it).

## Consequences

- **Throughput.** Stranded green work merges on its own; the ~21% finalization efficiency
  observed (≈80/h capacity vs ≈17/h realized) recovers toward capacity without touching the
  gates. This is the highest-leverage throughput fix found in the audit — downstream of the
  checks, not in them.
- **Soundness — none at risk.** ARM never bypasses a gate (GitHub enforces required checks
  before merging) and is restricted to proof-only diffs (gates/harness/workflows are excluded +
  CODEOWNERS-guarded). RERUN only re-runs Gate A — it cannot pass a bad proof; a re-run of a
  genuinely-failing proof would just fail again, which is why the cancellation classifier is
  strict (leaf/admission failures are never re-run).
- **Bounded + idempotent.** Both passes cap per run (arm ≤30, rerun ≤15) and act only on a
  positive recoverable signal, so a bad state can't cause a runaway.
- **Trust surface.** The janitor + its tool join the ADR-019 CODEOWNERS gate-tooling surface.

## Alternatives considered

- **Fix only the creation-time enrolment (no backstop).** Necessary but insufficient — a backstop
  is what makes finalization self-healing when the enrol step (or any future path) misses one.
- **Make the gate treat a CANCELLED leg as pass.** Unsound: a cancelled leg means that check did
  not complete; the gate genuinely didn't pass. Re-running is the only sound recovery.
- **Generalise `fork_automerge` to same-repo.** Rejected to keep ADR-068's fork path isolated and
  avoid a double-arm race; the new janitor explicitly excludes cross-repo PRs.

## References

ADR-068/SPEC-068-A (fork auto-merge — cross-repo only, the gap), ADR-005 (autonomous merge on
green), ADR-026 (prove PR titles), ADR-019 (CODEOWNERS trust surface), ADR-058 (gate-a required
context). Sibling janitors: dropped-gate / stale-failed-pr / superseded-pr / stale-branch.
Audit + remediation tracked on #5678.
