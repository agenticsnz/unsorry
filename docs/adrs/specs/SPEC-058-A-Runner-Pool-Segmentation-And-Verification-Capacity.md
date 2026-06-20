# SPEC-058-A: Runner Pool Segmentation and Verification Capacity Governance

Implements: [ADR-058](../ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md) | Status: Proposed | Updated: 2026-06-16

This spec defines the first operating contract for routing unsorry CI and
agent work across GitHub-hosted and namespace.so runner pools.

## 1. Runner Surfaces

### GitHub-hosted cheap lane

Use GitHub-hosted `ubuntu-latest` for:

- path detection,
- required-check aggregation,
- PR title, label, and scope checks,
- ADR/spec/documentation checks,
- generated-board refreshes,
- lightweight fork intake checks,
- any job that must not consume namespace verifier capacity.

These jobs must not become the sole source of a Lean soundness verdict.

### Namespace trusted verifier lane

Use namespace.so profiles for:

- Gate A Lean build/audit/replay jobs,
- central re-checks defined by ADR-049,
- verifier jobs that can admit content to `UnsorryLibrary`,
- evidence-producing verifier jobs that depend on namespace cache volumes or
  profile sizing.

Namespace runner logs, profile sizing, cache volumes, and queue behavior are
part of the operator-visible verifier surface.

## 2. Current Namespace Profiles

| Profile | Intended size | Use |
|---------|---------------|-----|
| `namespace-profile-unsorry-prepare` | 1 vCPU / 2 GB | prepare/build lane, cache warming, archive package validation |
| `namespace-profile-unsorry-audit` | operator-sized | serial axiom-audit lane |
| `namespace-profile-unsorry-replay` | 2 vCPU / 8 GB | leanchecker replay lane |

The workflow must route by verification job role, not by trust in the author.
A trusted maintainer PR that reaches kernel replay still uses the replay lane.
A fork PR that touches only docs remains cheap until it reaches a verifier
stage.

## 3. Required Routing Contract

`.github/workflows/gate-a.yml` must preserve this shape:

```text
detect:              GitHub-hosted
gate-a-prepare:      namespace-profile-unsorry-prepare
gate-a-audit:        namespace-profile-unsorry-audit
gate-a-replay:       namespace-profile-unsorry-replay
gate-a-archive:      namespace-profile-unsorry-prepare when archive paths changed
gate-a aggregate:    GitHub-hosted
```

The `detect` job emits the role-specific runner labels and per-job cache-volume
flags:

```text
prepare_profile = namespace-profile-unsorry-prepare
audit_profile   = namespace-profile-unsorry-audit
replay_profile  = namespace-profile-unsorry-replay
archive_profile = namespace-profile-unsorry-prepare
```

The olean-invalidating set still belongs to `tools.gate_a.parallel_modules`;
it decides whether replay/audit scope is incremental or full:

```text
lean-toolchain
lakefile.toml
lakefile.lean
lake-manifest.json
```

Changes to `tools/gate_a/**` and `.github/workflows/gate-a.yml` remain
Lean-relevant and trust-bearing, but they do not automatically select the heavy
replay scope unless they also invalidate oleans.

## 4. GitHub-Hosted Verifier Pilot Policy

GitHub-hosted `ubuntu-latest` may be evaluated as a routine verifier runner
because it can provide more plan-level concurrency than a small namespace
profile. It must not replace the role-specific Namespace verifier lanes as the
required Gate A verifier surface without evidence.

A valid pilot must be non-merge-blocking or limited to an explicitly approved
test branch, and must report:

- median and p95 wall time for `gate-a-prepare`, `gate-a-audit`, and
  `gate-a-replay`,
- cache-hit behavior for mathlib and `.lake/build`,
- queue wait time,
- failure and retry rate,
- whether `UNSORRY_REPLAY_CHUNK=6` is still required,
- whether GitHub-hosted storage is enough for the workflow,
- whether logs and job metadata are sufficient for operator debugging,
- cost/minute impact compared with namespace,
- effect on the existing open PR queue.

The pilot may become a later implementation PR if it shows that GitHub-hosted
runners are faster or cheaper without weakening the ADR-049 central re-check
contract. Until then, GitHub-hosted runners remain the cheap/intake and
aggregation lane, while namespace remains the trusted verifier lane.

## 5. Live Cutover Policy

Runner segmentation is a live operations change. It must handle existing PRs
and queued jobs, not only new work.

### 5.0 Coordinated prove admission governor

`swarm/agent.sh --prove` now has a cheap admission layer before the trusted
verifier lane. After syncing the repository, and before claim, unblock,
decompose, demote, or proof PR creation, the agent reads live GitHub state:

```text
open_prove_prs       = open PRs with titles beginning prove(
gate_a_in_flight     = queued gate-a.yml runs + in-progress gate-a.yml runs
```

The default policy is:

```text
UNSORRY_SUBMISSION_GOVERNOR=1
UNSORRY_MAX_OPEN_PROVE_PRS=40
UNSORRY_MAX_GATE_A_IN_FLIGHT=20
UNSORRY_SUBMISSION_FREEZE=0
UNSORRY_GOVERNOR_SCAN_LIMIT=200
```

If the freeze is truthy, or either threshold is reached, coordinated `--prove`
exits cleanly with no new claim and no new PR. If the GitHub API read fails,
the governor fails closed and pauses the cycle. Operators can set
`UNSORRY_SUBMISSION_GOVERNOR=0` for a deliberate override, or set either max to
`-1` to disable only that limit.

This is the first concrete two-layer implementation:

- **Cheap admission layer:** GitHub-hosted metadata/API visibility decides
  whether new proof work may enter the queue.
- **Trusted verifier layer:** namespace Gate A remains the only lane that can
  admit Lean content.

`--prove-local` and `--dry-run` are exempt because they produce no remote
claims, branches, PRs, or namespace verifier demand.

### 5.0.1 Queue-backed producer / dispatcher mode

The compatible cutover path is:

```text
old proof PRs already open       -> continue through the existing Gate A lane
new proof producers              -> default queued submit mode
queued proof branches            -> no PR, no Gate A spend
queue dispatcher                 -> opens bounded PRs when the governor allows
```

`./swarm/agent.sh --prove` still claims a goal, generates a proof, locally
verifies it, writes the same library/index/goal tree, and releases the claim.
By default it now pushes the verified tree to:

```text
queued/prove/<goal>/<agent>-<suffix>
```

`./swarm/agent.sh --dispatch-queue` fetches queued proof branches, skips any
branch that already has a PR, checks the same live admission governor, and
opens at most `UNSORRY_DISPATCH_LIMIT` PRs per pass.
`UNSORRY_GOVERNOR_WAIT` defaults to `300`, so producers and dispatchers poll
rather than exit when the governor is closed or no work is available.

This lets operators switch the production engine while the old PR queue drains:
existing PRs are untouched, existing required checks remain stable, and new
proof work does not consume GitHub PR or namespace Gate A capacity until the
dispatcher admits it.

### 5.0.2 Repository-side admission for uncontrolled producers

The queue-backed producer mode is cooperative: a running `agent.sh` process does
not hot-reload itself after `main` changes, and external contributors may run
custom scripts. The repository therefore enforces the same cutover policy at PR
ingress.

The cutoff is the merge time of the queued dispatcher:

```text
queued-proof cutover = 2026-06-16T22:24:44Z
```

Post-cutover PRs are rejected when they look like direct proof submissions:

```text
head ref starts with feature/goal-
head ref starts with prove/
title starts with prove(
```

Dispatcher submissions are admitted only through:

```text
queued/prove/<goal>/<agent>-<suffix>
```

`.github/workflows/pr-admission.yml` runs on `pull_request_target`, checks the
base-repository policy from `tools.repo.pr_admission`, labels rejected PRs
`blocked-direct-submit`, comments with restart instructions, and closes them.
Gate A, Gate B, `agent-lint`, `triviality`, and `attribution-advisory` run the
same admission check and short-circuit rejected PRs so that a direct-submission
flood cannot keep consuming GitHub-hosted or Namespace runner capacity while the
close workflow is pending.

### 5.1 Required-check continuity

The cutover must preserve required check names:

```text
gate-a
gate-b
```

Branch protection must not be changed merely to adopt this runner policy. The
aggregate `gate-a` job may continue to run on GitHub-hosted runners because it
only aggregates the namespace verifier jobs.

### 5.2 Existing PR handling

At cutover time, open PRs fall into four classes:

| PR state | Handling |
|----------|----------|
| Green and mergeable | May merge without rerun; verifier contract did not weaken |
| Queued | Let run drain unless queue pressure requires manual cancellation |
| In progress | Do not cancel unless superseded or clearly stuck |
| Failed/stale | Maintainer chooses rerun, rebase, or close/recreate |

Existing PRs do not need to be mass-rebased only to adopt comments or docs. A
material workflow routing change may require a rebase/rerun, but this ADR's
initial adoption is policy and documentation over the existing routing shape.

### 5.3 Queue drain procedure

Before changing actual runner profile sizes, operators should:

1. Capture the current open PR count and queued Gate A count.
2. Pause new autonomous proof PR creation if the namespace queue is already
   saturated.
3. Keep `namespace-profile-unsorry-prepare`, `namespace-profile-unsorry-audit`, and `namespace-profile-unsorry-replay` available.
4. Let existing in-progress Gate A jobs finish.
5. Cancel only superseded or clearly stuck runs.
6. Confirm new PRs route prepare/archive work to `namespace-profile-unsorry-prepare`, audit work
   to `namespace-profile-unsorry-audit`, and replay work to `namespace-profile-unsorry-replay`.
7. Let producer agents pull/re-exec the latest harness, or restart them if
   they are inside a long provider call; default coordinated `--prove` now
   queues verified branches.
8. Start one dispatcher with `./swarm/agent.sh --dispatch-queue` and a small
   `UNSORRY_DISPATCH_LIMIT`.
9. Wait for one scheduled `gate-a-full-replay` run after the cutover.
10. Record the cutover event with profile sizes and queue state.

The pause in step 2 can be manual at first. ADR-053/ADR-054 should later make
it an explicit claim/quota control.

### 5.4 Rollback

Rollback must preserve the required contexts. Valid rollback actions are:

- resize one role-specific Namespace profile upward without changing the workflow,
- temporarily point the affected job at a larger Namespace profile,
- pause new autonomous proof PR creation,
- re-run failed Gate A jobs after capacity is restored,
- revert the workflow routing PR if a routing change, not capacity, caused the
  failure.

Do not roll back by disabling Gate A, removing branch protection, or accepting
a fork/client verifier result.

## 6. Fork Intake Policy

Fork PRs are safe from a soundness perspective only because ADR-049 keeps the
central verifier authoritative. They are still a capacity and abuse risk.

Before a fork PR can spend namespace verifier capacity, the system should run
cheap GitHub-hosted intake checks:

- path classification,
- whether Lean-relevant files changed,
- PR size,
- contributor status or reputation tier,
- whether maintainer approval is required,
- whether a duplicate proof target is already in flight.

Until ADR-054 quotas are implemented, maintainer approval is the default
governor for unknown fork contributors reaching namespace verifier jobs.

## 7. Agent and Generated-Artifact Policy

Agent exploration, proof attempts, retries, and candidate generation are not
trusted verifier work. They should run:

- locally on the contributor/agent machine,
- on a separate agent worker pool,
- or on GitHub-hosted jobs only when cheap and non-secret.

Generated artifacts should default to GitHub-hosted runners unless the artifact
is verifier evidence that requires namespace cache state or trusted verifier
context.

## 8. Capacity Math

If a verifier run takes six minutes of exclusive namespace capacity, one runner
provides about ten verifier slots per hour:

```text
60 minutes / 6 minutes per PR = 10 PR verifier slots per hour
```

Ten active contributors can exceed that quickly. Therefore:

- cheap checks must short-circuit non-Lean PRs before namespace use,
- superseded PR runs must be cancelled,
- full replay must stay rare and isolated,
- unknown fork and agent work must have quota or approval,
- queue depth and median wait time should be visible to operators.

## 9. Observability Requirements

The operator dashboard or generated status pack should report:

- active GitHub-hosted cheap-lane jobs,
- active namespace verifier jobs,
- queued namespace verifier jobs,
- average verifier wait time,
- per-profile runner-minute usage,
- number of cancelled superseded runs,
- number of fork PRs waiting for approval,
- number of heavy-profile runs triggered by olean-invalidating changes.

GitHub-hosted concurrency is useful but plan-dependent. The repository should
not encode a fixed GitHub-hosted concurrency number as a correctness
assumption.

## 10. Safety Requirements

- A GitHub-hosted cheap check may block or classify work, but must not admit
  Lean proofs.
- A namespace verifier job must never trust contributor-supplied oleans as a
  soundness input.
- The aggregate required check may run on GitHub-hosted runners only because it
  depends on namespace verifier job results.
- Fork PR verifier access must be governed by approval or quota until ADR-054
  is implemented.
- Runner profile size may change, but workflow comments and specs must be
  updated in the same PR as an intentional sizing change.
- GitHub-hosted verifier routing must be introduced as a measured pilot before
  it can become the required Gate A lane.

## 11. Acceptance Criteria

ADR-058 is implemented when:

- Gate A detection and aggregation remain on GitHub-hosted runners.
- Gate A verifier jobs remain on namespace profiles.
- Prepare/archive work routes to `namespace-profile-unsorry-prepare`.
- Axiom audit work routes to `namespace-profile-unsorry-audit`.
- Kernel replay work routes to `namespace-profile-unsorry-replay`.
- Existing docs/specs describe the current role-specific namespace profile split.
- Fork-support work references this runner policy before enabling automated
  namespace verifier spend for unknown contributors.
- The cutover procedure accounts for open PRs, queued Gate A runs, and
  in-progress namespace jobs.
- Required check names remain stable through the transition.
- A future GitHub-hosted verifier migration has a measured pilot before any
  required verifier context is moved.

## 12. Out of Scope

- Purchasing a larger runner plan.
- Replacing namespace.so.
- Implementing ADR-054 reputation and quota storage.
- Rewriting Gate A control flow.
- Making GitHub-hosted runner concurrency a guaranteed service-level objective.
