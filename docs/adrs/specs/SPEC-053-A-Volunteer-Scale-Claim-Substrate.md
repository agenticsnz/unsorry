# SPEC-053-A: Volunteer-Scale Claim Substrate

Implements: [ADR-053](../ADR-053-Volunteer-Scale-Claim-Substrate.md) | Status: Proposed | Updated: 2026-06-15

This spec defines the claim/lease contract for volunteer-scale autonomous
trunk projects. It preserves ADR-004 semantics while allowing implementations
other than a single git branch.

## 1. Goals

- Preserve one live owner per constrained claim slot.
- Avoid duplicate work where policy says only one worker should proceed.
- Scale lease acquisition beyond one hot git branch.
- Keep canonical work state and accepted results in the repository.
- Export claim evidence for audit and incident review.

## 2. Required Operations

```text
acquire(work_unit_id, agent_id, ttl, metadata) -> Lease | Conflict | Denied
renew(lease_id, agent_id, ttl) -> Lease | Expired | Denied
release(lease_id, agent_id, reason) -> Released | Denied
expire(now) -> [ExpiredLease]
inspect(work_unit_id) -> LeaseState
list(filter) -> [LeaseState]
export_events(range) -> ClaimEventBatch
```

All operations must be idempotent where a caller may retry after a timeout.

## 3. Lease Record

```text
Lease {
  lease_id
  work_unit_id
  agent_id
  acquired_at
  expires_at
  generation
  substrate
  metadata
}
```

`generation` increments on successful renewal and prevents stale release or
renew operations from overwriting newer state.

## 4. Event Record

```text
ClaimEvent {
  schema_version
  event_id
  event_type        # acquired | renewed | released | expired | denied
  lease_id
  work_unit_id
  agent_id
  occurred_at
  substrate
  reason
  metadata_hash
}
```

Events should be append-only. If a live service is used, periodic event batches
must be exported into repository evidence.

## 5. Backends

| Backend | Suitable scale | Write access | Notes |
|---------|----------------|--------------|-------|
| **Claimless + merge-time dedup** | forks / Tier 0 | none (read-only) | No lease; the degenerate point of this contract. `acquire` always succeeds; "one live owner" is enforced by the upstream kernel + first-merge-wins, not by a lease. The **fork onramp** (ADR-068 / SPEC-068-A): a fork that cannot write `origin/claims` proves claimless and submits by cross-repo PR. Cost: duplicate verifier work, never soundness. |
| Single `claims` branch | controlled swarm | upstream write | Current ADR-004 behavior; simplest audit story |
| Sharded claims branches | medium fleets | upstream write | Reduces branch hot-spotting but keeps git write contention |
| Lease API + durable store | volunteer fleets | broker-mediated | Better concurrency; requires auth, uptime, evidence export. A **fork-writable** broker (GitHub App / token-scoped endpoint) is what lets forks *claim* rather than go claimless — a Phase-2 backend, paired with ADR-054 identity/quota. |
| Append-only signed log | high auditability | fork-appendable | Forks can append claim events (e.g. via PR / API) for later reconstruction; needs compaction/read model |

The backend is an implementation detail. The contract and evidence are the
portable surface. **Access vs contention:** the upstream-write backends solve
*contention*; the claimless and fork-writable rows solve *access* for
contributors with no upstream write (ADR-068 ships the claimless row now; the
fork-writable lease is justified only when measured duplicate-verifier waste
warrants it).

## 6. Failure Behavior

- If lease acquisition is unavailable, workers must not start new claimed work.
- If renewal fails, workers must stop before submitting results unless policy
  allows best-effort completion.
- If evidence export fails, operators must see degraded auditability.
- If the substrate forks or loses state, repository evidence and accepted
  results remain canonical; live leases can be discarded and rebuilt.

## 7. Metrics

Implementations should report:

- claim attempts,
- conflicts,
- denied claims,
- acquisition latency,
- renewals,
- expirations,
- stale leases,
- backend errors,
- per-agent live leases,
- per-work-unit contention.

## 8. Fork-writable substrate (Phase 2, evidence-gated)

ADR-068 shipped the **claimless** fork onramp (the degenerate "no-lease" backend
above). This section is the plan for the fork-*writable* lease — needed only if
forks coordinating purely by merge-time dedup waste too much verifier capacity.
The whole sequence is gated on the **ADR-070** duplicate-verifier-waste metric; it
is sequenced cheapest-first so the operational dependency a real lease introduces
is paid only on evidence.

### 8.1 The gate (2a)

The ADR-070 metric reports the share of Gate A runs spent on cross-repo (fork)
prove PRs that never merged — the loser of first-merge-wins. If that share is
small, **nothing below is built**: ADR-064 goal-level dedup and the ADR-058
governor already bound the cost, and a lease would add an operational dependency
for no measured benefit (ADR-004's caution).

### 8.2 Identity + quota at the enabler (2b)

The first mitigation needs no lease. The Phase-1 `fork-automerge-enabler`
(`tools.repo.fork_automerge`) is the single chokepoint every fork contribution
passes through; SPEC-054-A extends its admissibility selector with per-owner open-
PR caps, a denylist, trial/trusted tiering, and an emergency pause. This delivers
most of ADR-054's abuse control by reusing existing infrastructure.

### 8.3 Sharded fork selection (2c)

A second claimless mitigation, still **no lease**: each fork deterministically
owns a slice of the open-goal space, `shard = H(agent_id) mod K`, and selects
preferentially within its slice (advisory only — never a correctness input; the
kernel + first-merge-wins remain the backstop). This lowers the probability two
forks pick the same goal without any coordination round-trip. `K` and the
fall-through policy (a fork may step outside its shard when its slice is dry) are
policy values.

### 8.4 The fork-writable lease (2d)

Built only if 2a shows residual waste 2b/2c do not remove. It realises the §2–§4
contract over a backend a fork (no upstream write) can reach. Two candidates,
decided at 2d-time on the evidence:

| Backend | Latency | Dependency | Identity | Notes |
|---|---|---|---|---|
| **Append-only claim log via fast-merge PR** | seconds–minutes (PR merge) | none new (git + gates) | the PR author | Forks open a tiny claim PR an auto-merge lands on a `claims-log` ref; the log is the lease. Coarse leases; a mine-vs-merge race window (as ADR-060 sourcing already accepts). **Preferred** — keeps the repo as source of truth. |
| **GitHub-App lease broker** | sub-second | a hosted service (uptime/auth) | the App-authenticated account | True low-latency leases and the natural ADR-054 enforcement home; reintroduces the operational dependency ADR-004 avoided. Only for a genuinely large public fleet. |

Either way, lease decisions are **exported back into repository evidence** (§4) so
the live substrate never becomes an invisible source of truth, and acquisition is
quota-checked against the SPEC-054-A identity before it is granted.

## 9. Out of Scope

- Agent identity and reputation **policy** (SPEC-054-A owns it; this contract only
  consumes the identity at acquire-time).
- Verification tier policy.
- Replacing GitHub as merge authority.
- Standing up a hosted claim service before the ADR-070 metric justifies 2d.
