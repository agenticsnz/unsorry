# ADR-070: Duplicate-Verifier-Waste Metric

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-070 |
| **Initiative** | volunteer-scale orchestration / Phase-2 instrumentation |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-18 |
| **Status** | Proposed |

## Context

ADR-068 shipped fork-native contribution as a **claimless** path: a fork proves
without a claim and submits a cross-repo PR, accepting that two forks may prove
the same goal and each consume a Gate A run before first-merge-wins closes the
loser. The cost is verifier capacity, never soundness.

Phase 2 — a fork-writable lease (ADR-053 §8.4) and an identity/quota layer
(ADR-054) — exists to eliminate that duplication. But ADR-053's own rollout is
explicit: *"pilot a sharded or API-backed substrate only when measured contention
justifies it."* Today there is **no measurement**. The decision to build (or not
build) a lease — an operational dependency ADR-004 deliberately avoided — is
currently a guess. ADR-064 goal-level dispatch dedup and the ADR-058 governor
already bound duplicate prove work; if the residual fork duplication is small, the
lease should not be built at all.

The missing piece is a number: **how much Gate A capacity do claimless fork
duplicates actually waste?** That number is the gate for SPEC-053-A §8.3 (sharded
selection) and §8.4 (the lease), so it must exist before either.

## WH(Y) Decision Statement

**In the context of** a claimless fork onramp (ADR-068) that trades possible
duplicate-verifier work for zero-coordination simplicity, and a Phase-2 lease
(ADR-053) whose own rollout gates construction on *measured* contention,

**facing** the absence of any measurement of that waste — so the build-the-lease
decision (with its operational dependency) is unevidenced, even though ADR-064
dedup and the ADR-058 governor may already keep the waste negligible,

**we decided for** a **read-only duplicate-verifier-waste metric**
(`tools.repo.fork_waste`): a pure, unit-tested summariser over the prove-PR
history (from `gh pr list`) that reports, per goal and in aggregate, how many
cross-repo (fork) `prove(<goal>):` PRs were opened, how many merged, and how many
**closed without merging** — the loser of first-merge-wins, each of which spent
≥1 Gate A run for nothing — plus the fork-collision rate and an estimated
wasted-Gate-A-run count; published as `docs/metrics/fork-waste.json` and refreshed
by a scheduled workflow (the `queue-board` pattern: `REFRESH_TOKEN`, report-only
when unset, `[skip ci]` commit),

**and neglected** instrumenting at the workflow-run level for exact Gate A minutes
(rejected for the MVP — a closed-unmerged prove PR is a sufficient, far cheaper
proxy for "its verifier work was wasted"; per-run minutes can refine later),
building a board/HTML page now (deferred — a JSON artifact plus a human summary is
enough to read the number and gate the decision), and feeding the metric back into
the harness as a control input (rejected — it is advisory measurement; selection
and admission must never depend on it, mirroring ADR-064's best-effort posture),

**to achieve** the evidence that decides whether Phase-2 sharded selection
(SPEC-053-A §8.3) or a fork-writable lease (§8.4) is worth building — so the
operational dependency is paid only if the data demands it,

**accepting that** the metric is a **proxy** (PR outcome, not exact Gate A
minutes; a closed-unmerged prove PR is counted as waste regardless of *why* it
closed, which slightly over-counts), that it attributes waste to the cross-repo
(fork) subset of prove PRs, and that it is best-effort (a `gh` error yields an
empty summary, never a failure) — all acceptable because the metric informs a
human build/no-build decision, never a runtime control path.

## What the metric reports (summary; full contract in SPEC-070-A)

Per goal and aggregate, over all `prove(<goal>):` PRs:

- `fork_prove_prs`, `fork_merged`, `fork_open`, `fork_closed_unmerged` (the waste);
- `fork_waste_ratio` = closed-unmerged ÷ fork prove PRs;
- `goals_with_fork_collision` (a goal with >1 prove PR and ≥1 fork PR);
- `estimated_wasted_gate_a_runs` (≥1 per closed-unmerged fork PR — a lower bound);
- the worst few colliding goals.

## Consequences

- **Positive.** Turns the Phase-2 build/no-build decision from a guess into an
  evidence-gated one (SPEC-053-A §8.1), and may show that ADR-064 + the governor
  already make a lease unnecessary.
- **Positive.** Pure summariser + the established board-refresh pattern: small,
  read-only, no new trust surface, no harness coupling.
- **Negative.** A proxy — PR outcome, not exact Gate A minutes — and it slightly
  over-counts (a fork PR closed for a non-duplicate reason still counts as waste).
- **Negative.** A scheduled refresh adds one more `REFRESH_TOKEN` workflow (it
  degrades to report-only when the secret is unset).

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Duplicate-verifier-waste metric spec | Specification | specs/SPEC-070-A-Duplicate-Verifier-Waste-Metric.md |
| REF-2 | Fork-Native Contribution Mode (the claimless source of the waste) | Decision | ADR-068-Fork-Native-Contribution-Mode.md |
| REF-3 | Volunteer-Scale Claim Substrate (what the metric gates) | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-4 | Agent Identity, Quotas, and Reputation | Decision | ADR-054-Agent-Identity-Quotas-And-Reputation.md |
| REF-5 | Goal-Level Dispatch Deduplication | Decision | ADR-064-Goal-Level-Dispatch-Deduplication.md |
| REF-6 | Runner-Pool Segmentation and Verification Capacity (governor) | Decision | ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-7 | Proof Provenance and Leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-18 |
