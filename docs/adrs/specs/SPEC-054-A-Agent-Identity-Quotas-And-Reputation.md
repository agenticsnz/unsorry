# SPEC-054-A: Agent Identity, Quotas, and Reputation

Implements: [ADR-054](../ADR-054-Agent-Identity-Quotas-And-Reputation.md) | Status: Proposed | Updated: 2026-06-15

This spec defines the identity and quota model for volunteer-scale autonomous
work. It controls access to work; it does not decide whether submitted work is
correct.

## 1. Identity Record

```text
AgentIdentity {
  agent_id
  owner_id
  public_key_or_account
  tier
  created_at
  status            # active | paused | revoked
  quota_profile
  reputation
  metadata
}
```

`owner_id` is the accountable human, organization, or maintainer-approved
fleet owner behind the agent.

## 2. Quota Profile

```text
QuotaProfile {
  max_live_leases
  max_prs_open
  max_claims_per_hour
  max_failures_per_window
  allowed_work_risk
  allowed_verification_tiers
  cooldown_policy
}
```

Quotas must be enforced before claim acquisition and before PR submission.

## 3. Reputation Events

```text
ReputationEvent {
  event_id
  agent_id
  event_type
  work_unit_id
  verifier_tier
  delta
  reason
  evidence_ref
  occurred_at
}
```

Positive events require verifier-backed evidence. Negative events include
lease hoarding, repeated infrastructure failures, policy violations, or
operator-confirmed abuse.

## 4. Tier Policy

| Tier | Typical quota | Notes |
|------|---------------|-------|
| `observer` | none | Can inspect status only |
| `trial` | 1 live low-risk claim | Default for new volunteers |
| `trusted` | multiple claims, normal work | Earned through accepted outcomes |
| `operator` | fleet controls | Requires maintainer approval |
| `maintainer` | policy and revocation | Trust-bearing authority |

Projects may tune exact numbers in policy files.

## 5. Abuse Controls

The implementation should support:

- per-owner caps across many agent ids,
- cooldowns after repeated failures,
- work-risk ceilings by tier,
- revocation with reason,
- emergency pause of all volunteer claims,
- denylist for compromised identities,
- audit events for all quota overrides.

## 6. Privacy and Transparency

Public leaderboards should credit work without exposing unnecessary secrets or
private account metadata. Governance actions that affect access should retain
enough reason and evidence for later review.

## 7. Phase-2 enforcement slice (the fork onramp)

The minimal, evidence-gated realisation that controls fork-contribution abuse
without a full identity service or a lease (gated on the ADR-070 metric; sequenced
in SPEC-053-A §8.2). It enforces a subset of §2/§4/§5 at the one chokepoint that
already exists — the `fork-automerge-enabler` (ADR-068 / SPEC-068-A §6):

- **Identity** = the GitHub account that opened the cross-repo PR; `owner_id` is
  that account (or a maintainer-mapped fleet owner). No new identity record store
  is required for the slice — the PR carries the identity.
- **Quota at the chokepoint.** Extend the `tools.repo.fork_automerge` selector so a
  fork PR is admissible only if its owner is under `max_prs_open` (per-owner open
  cross-repo prove PRs), not on the **denylist**, within its tier's ceiling, and
  the global **emergency pause** is off. These are read from a small policy file
  (`tools/repo/fork_policy.*`), versioned in-repo and auditable.
- **Tiers.** A new owner is `trial` (low concurrency); promotion to `trusted`
  reads accepted-proof provenance (§ below) — no manual maintenance.
- **Emergency pause / revocation** reuse the enabler's existing fail-soft: pause =
  arm nothing this run; revoke = denylist entry with a reason.

### 7.1 Reputation derivation (no parallel store)

`ReputationEvent`s of type "accepted verified work" (§3) are **derived** from the
existing `⟦Π:Provenance⟧{solver≜…}` of merged `library/index` entries (ADR-023),
not separately recorded. A `trial → trusted` promotion is a threshold on that
derived count. Negative events (lease hoarding, repeated infra failures, abuse)
are recorded explicitly, since they have no merged-proof footprint.

## 8. Out of Scope

- Cryptographic identity protocol selection.
- Payments, collateral, or token economics.
- Verification correctness.
- Claim substrate implementation (SPEC-053-A owns it).
