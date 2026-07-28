# SPEC-117-A: GitHub-Hosted Gate A Runners

Implements: [ADR-117](../ADR-117-GitHub-Hosted-Gate-A-Runners.md) · Status: Accepted · Updated: 2026-07-28

## Behaviour

Every Gate A lane runs on GitHub-hosted `ubuntu-latest` instead of the lapsed Namespace
label. The build cache degrades automatically from the Namespace `.lake` volume to the
ADR-045 `actions/cache` path. No job's steps, conditions, or soundness bar change.

## Components

### `.github/workflows/gate-a.yml` — the `profiles` step

The four label assignments change target:

```
prepare=ubuntu-latest
audit=ubuntu-latest
replay=ubuntu-latest
archive=ubuntu-latest
```

The single-lane consolidation of ADR-058 is preserved — one label for all four lanes, so
no lane can be left at zero runners independently of the others. Only the substrate moves.

Nothing else in the step changes. The existing failsafe classifier is what carries the
cache switch, and it already handles this case:

```bash
case "$label" in
  namespace-*) value=true ;;
  *)           value=false ;;
esac
```

With `ubuntu-latest`, every `*_volume` output becomes `false`, which:

- **skips** the `Namespace .lake cache volume` and `Namespace .lake cache diagnostics`
  steps (`if: …_volume == 'true'`),
- **enables** `Cache local Lake build (.lake/build) — incremental library (ADR-045)`
  (`if: …_volume != 'true'`),
- **skips** `Publish library oleans to fallback cache` (`if: … && …_volume == 'true'`).

### `.github/workflows/gate-a.yml` — `gate-a-prepare` timeout

`timeout-minutes: 45` → `120`, matching the cap `gate-a-replay`, `gate-a-archive` and
`gate-a-benchmark` already use.

A cold `lake build UnsorryLibrary --wfail` does not fit in 45 minutes on the 4-vCPU
GitHub-hosted lane. Measured on this change's own PR: `[9150/10062]` (~91%) still
compiling cleanly at ~6s/module when the cap cancelled the job — no error, no disk
exhaustion, no memory pressure, purely wall clock.

The cancellation is self-perpetuating, which is why the cap must move rather than the
run simply being retried: `actions/cache` saves in a post-step that does not run on a
cancelled job, so a timed-out cold build seeds nothing and the next run starts cold
too. One completed cold run breaks the cycle; from then on ADR-045 incrementality
keeps the warm path to minutes.

### Out of scope for this change

Three workflows keep the `namespace-profile-unsorry-1` label and will accumulate queued
runs on their schedules. **None gates a merge**, and each needs its own disposition:

| Workflow | Trigger | Why it is not switched here |
|---|---|---|
| `lake-volume-janitor.yml` | schedule | Maintains the Namespace `.lake` volume; meaningless without that volume — it should be disabled, not retargeted |
| `gate-a-full-replay.yml` | schedule | Full-corpus replay; its cost profile on 4 vCPU needs its own assessment before retargeting |
| `independent-check-backstop.yml` | schedule | Advisory (ADR-096), non-gating; retarget or disable on its own merits |

`export-checker-pilot.yml` and `gate-a-shard-pilot.yml` also keep the label but are
`workflow_dispatch`-only, so they never fire unattended and cost nothing.

## Acceptance

1. `repos/agenticsnz/unsorry/actions/runners` reporting `total_count: 0` no longer stalls
   Gate A: a Lean-touching PR reaches a terminal Gate A conclusion without a self-hosted
   runner.
2. A **benchmark** proof PR (touching `targets/<suite>/_verify/**` plus `.aisp` records)
   runs `gate-a-benchmark` to completion and skips the repo-library build, because
   `detect`'s `active` filter does not match those paths.
3. A PR touching `library/**` restores or populates the `actions/cache` entry for
   `.lake/build` and completes `gate-a-prepare` within its cap.
4. No change to which checks are required, to the axiom whitelist, or to any `--wfail` bar.

## Verification

- `python3 -m tools.gate_b validate .` — exit 0.
- `./swarm/agent.sh --self-test` — green.
- Workflow YAML parses (`actionlint` in the `agent-lint` check).
- Live evidence: PR #7160, previously queued indefinitely, reaches a Gate A conclusion.
