# ADR-058: Runner Pool Segmentation and Verification Capacity Governance

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-058 |
| **Initiative** | unsorry CI scalability and fork-safe verification |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-16 |
| **Status** | Proposed |

## Context

ADR-049 makes unsorry safe for untrusted contributors by keeping the
load-bearing soundness verdict on a project-controlled central re-check. Issue
#1206 then shows the next constraint: non-contributor fork support and larger
agent fleets can make verification capacity the bottleneck even when soundness
is already safe.

The current Gate A workflow already has the useful split:

- cheap detection and aggregation jobs run on GitHub-hosted `ubuntu-latest`,
- trusted Lean verification jobs run on namespace.so profiles,
- prepare/build work routes to `namespace-profile-unsorry-prepare`,
- axiom audit work routes to `namespace-profile-unsorry-audit`,
- kernel replay work routes to `namespace-profile-unsorry-replay`.

That split should become an explicit policy. GitHub-hosted runners are useful
as cheap elastic intake capacity, but they give less control and operational
visibility than the namespace lane. Namespace runners provide the better
surface for trusted Lean verification because the project controls the profile,
cache volume, sizing, and logs around the verifier boundary.

As of this decision, the operating model is:

- `namespace-profile-unsorry-prepare`: small prepare/build profile for cache warming, goal builds,
  statement bindings, and archive package validation.
- `namespace-profile-unsorry-audit`: axiom-audit profile sized for one resident mathlib image.
- `namespace-profile-unsorry-replay`: replay profile sized for leanchecker and full-replay
  headroom.
- GitHub-hosted runners: cheap actions, protocol checks, docs checks, PR
  intake, labels, generated-board refreshes, and final aggregation.

## WH(Y) Decision Statement

**In the context of** unsorry scaling from trusted same-repo agents toward fork
contributors, volunteer agents, and more parallel PRs,

**facing** the fact that a single PR can consume several minutes of runner time,
and that letting fork, agent, generated-artifact, and trusted verifier jobs
compete in one capacity pool would create queue starvation and CI denial-of-
service pressure,

**we decided for** explicit **runner pool segmentation and verification
capacity governance**: GitHub-hosted runners are the cheap/intake lane for
low-trust, low-cost, and non-Lean work; namespace.so runners are the trusted
verification lane for Gate A and any future central re-check that can admit
content to the verified library; `namespace-profile-unsorry-prepare`, `namespace-profile-unsorry-audit`, and
`namespace-profile-unsorry-replay` split the trusted verifier work by job role so the operator can
scale prepare/build, axiom audit, and kernel replay capacity independently,

**and neglected** a single shared runner pool (rejected because noisy agent and
fork work can starve merge-blocking verification), GitHub-hosted runners as the
only verifier surface or a direct replacement for the role-specific Namespace
verifier lanes (rejected because
the trusted Lean lane needs stronger profile control, cache-volume control, and
visibility; GitHub-hosted concurrency is useful enough to pilot, but not enough
to make the protected verifier lane opaque by default), namespace runners for every
cheap job (rejected because that wastes paid verifier capacity), contributor
self-hosted runners as a merge-blocking verifier (rejected by ADR-049), and
scaling first by making all runners larger (rejected because capacity isolation
and queue policy are the first-order problem),

**to achieve** a CI architecture where cheap checks stay cheap, trusted
verification stays protected, fork support can be opened without granting
unbounded access to paid verifier minutes, and operator-visible namespace
capacity is reserved for the work that actually carries soundness,

**accepting that** GitHub-hosted runner concurrency and queue visibility are
plan-dependent, that namespace capacity costs more per trusted minute, that
some comments/specs must be kept in sync with operator-side profile sizing, and
that future fork automation must add identity/quota controls before it can
freely spend namespace verifier capacity.

## Runner Classes

| Class | Runner surface | Trust / cost role | Examples |
|-------|----------------|-------------------|----------|
| Cheap intake | GitHub-hosted `ubuntu-latest` | Low-cost checks before verifier spend | path filters, PR labels, ADR/spec lint, protocol checks |
| Required aggregator | GitHub-hosted `ubuntu-latest` | Stable required context wrapper | final `gate-a`, `gate-b` aggregation |
| Prepare verifier | `namespace-profile-unsorry-prepare` | Trusted build/cache preparation | goal builds, statement bindings, archive package validation |
| Audit verifier | `namespace-profile-unsorry-audit` | Trusted axiom-audit verification | serial `axiom_audit` over changed scope |
| Replay verifier | `namespace-profile-unsorry-replay` | Trusted kernel replay | incremental replay and forced full replay |
| Scheduled backstop | namespace profile selected by verifier policy | Defense-in-depth verification | daily full replay with small replay chunk |
| Generated artifacts | GitHub-hosted unless verifier evidence is required | Interruptible maintenance | leaderboard, targets board, visualization refresh |
| Agent exploration | contributor/local or separate agent pool | Noisy advisory work | local proving, retries, candidate generation |

## Capacity Rules

- Cheap GitHub-hosted checks should run before namespace verifier jobs wherever
  possible.
- Fork PRs and unknown agents should not directly spend namespace verifier
  minutes without intake checks, maintainer approval, or future ADR-054 quota
  policy.
- Required merge-blocking verifier jobs must have their own namespace lane and
  must not be starved by generated artifacts or agent exploration.
- A workflow that can admit content to `UnsorryLibrary` must use the trusted
  verifier lane defined by ADR-049.
- Gate A jobs should target their role-specific profiles: prepare/archive on
  `namespace-profile-unsorry-prepare`, audit on `namespace-profile-unsorry-audit`, and replay on `namespace-profile-unsorry-replay`.
- Superseded runs should be cancelled by concurrency groups so stale commits do
  not occupy trusted verifier capacity.
- Runner sizing is an operator-controlled capacity property; the repository
  records the current intended size and routing contract, but correctness must
  not depend on a hidden profile size.
- Switching routine Gate A from the Namespace verifier lanes to GitHub-hosted
  runners requires a shadow benchmark or pilot PR first. The pilot must compare wall time, cache
  restore behavior, failure modes, queue wait, and verifier log quality against
  the namespace lane before any required check is moved.

## Live Operations Transition

This decision is not allowed to assume an empty queue. The repository already
has open proof PRs, queued GitHub-hosted checks, queued namespace Gate A jobs,
and in-progress verifier runs. Runner segmentation must therefore be adopted as
a live operations change.

The transition rules are:

- Do not rename required contexts. `gate-a` and `gate-b` remain the branch
  protection contexts during the transition.
- Do not rename namespace profiles during the transition. `namespace-profile-unsorry-prepare`,
  `namespace-profile-unsorry-audit`, and `namespace-profile-unsorry-replay` remain stable routing labels.
- Do not cancel all existing PR runs as part of the cutover. Superseded runs may
  be cancelled by existing concurrency groups, but active PRs should either
  finish on their current workflow revision or be explicitly rebased/rerun.
- Existing green PRs may merge under the previous workflow revision if they
  already passed the protected checks. The verifier contract did not weaken.
- Existing queued or failed PRs may be re-run under their current revision, or
  rebased onto the new routing docs/policy when a maintainer wants the new
  metadata and comments to apply.
- Keep both namespace profiles available until the open PR queue has drained
  through at least one normal Gate A cycle and one scheduled backstop has
  completed.
- If queue depth is already high, pause new autonomous proof PR creation before
  changing runner capacity.
- Record the cutover as an operator event: timestamp, open PR count, queued
  Gate A count, namespace profile sizes, and any manual cancellations.

The intended migration is additive: the PR documents and clarifies the routing
contract without changing required-check names or the soundness boundary. Future
workflow rewrites that materially change routing must carry their own live
operations plan.

## Consequences

- **Positive.** GitHub-hosted runners absorb cheap PR and docs traffic without
  spending namespace verifier minutes.
- **Positive.** Namespace runners remain reserved for trusted verifier work,
  where cache volumes, profile sizing, and log visibility matter.
- **Positive.** Fork support has a clear governor: fork work can be cheap until
  it earns or receives access to the trusted verifier lane.
- **Positive.** The existing Gate A split becomes an explicit platform contract
  instead of an implicit workflow detail.
- **Negative.** Operator profile changes must be reflected in docs/specs or the
  repository will mislead maintainers.
- **Negative.** GitHub-hosted runner concurrency is useful but plan-dependent,
  so queue guarantees cannot rely on an undocumented fixed number.
- **Negative.** More lanes mean more policy surface: labels, path filters,
  concurrency groups, and quotas must remain understandable.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Runner pool segmentation spec | Specification | specs/SPEC-058-A-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-2 | Decentralised CI Runner Architecture | Decision | ADR-049-Decentralised-CI-Runner-Architecture.md |
| REF-3 | Verify-on-Ingest | Decision | ADR-048-Verify-On-Ingest.md |
| REF-4 | Gate A Workflow | Specification | specs/SPEC-006-B-Gate-A-Workflow.md |
| REF-5 | Volunteer-Scale Claim Substrate | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-6 | Agent Identity, Quotas, and Reputation | Decision | ADR-054-Agent-Identity-Quotas-And-Reputation.md |
| REF-7 | Non-contributor proof submission via forks | Issue | GitHub issue #1206 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-16 |
