# ADR-054: Agent Identity, Quotas, and Reputation

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-054 |
| **Initiative** | unsorry volunteer-scale trust and abuse control |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-15 |
| **Status** | Proposed |

## Context

ADR-053 separates claim semantics from the current git-branch substrate so
larger fleets can acquire work without branch-level contention. That creates a
second volunteer-scale problem: if anyone can create unlimited agent identities
and claims, hostile or careless participants can starve the queue, flood CI,
exhaust API limits, or claim high-value work without a history of successful
contributions.

The current swarm is controlled enough that GitHub identity and practical
write access are a sufficient boundary. A public volunteer model is different.
It needs explicit identity, quotas, reputation, revocation, and escalation
rules. These controls must manage abuse without weakening the core principle
that accepted work is judged by verifiers, not by social trust.

## WH(Y) Decision Statement

**In the context of** volunteer-scale autonomous work where many independent
humans and agent fleets may request claims and submit work,

**facing** Sybil attacks, hostile leases, CI flooding, duplicate identities,
credit gaming, and accidental over-consumption by well-intentioned fleets,

**we decided for** an explicit **agent identity and quota layer**: every agent
gets a stable identity bound to a contributor or organization, quota tiers
limit concurrent leases and PR submissions, reputation increases only from
accepted verifier-backed outcomes, high-risk work requires higher trust tiers
or approval, and operators can revoke, pause, or downgrade identities while
preserving an auditable reason,

**and neglected** trusting self-declared agent names (rejected because names are
cheap to forge), relying only on lease TTLs (rejected because attackers can
renew or re-claim indefinitely), and using reputation as a replacement for
verification (rejected because reputation controls access, not correctness),

**to achieve** controlled volunteer growth where useful contributors can scale
up while abusive or misconfigured fleets are contained,

**accepting that** identity and reputation introduce governance decisions that
must be transparent, appealable where appropriate, and separated from the
mathematical or technical verifier decision.

## Trust Tiers

Initial trust tiers:

| Tier | Capability |
|------|------------|
| `observer` | read-only, no claims |
| `trial` | low-risk claims, small concurrency, no high-value work |
| `trusted` | higher claim/PR quotas after accepted outcomes |
| `operator` | fleet management and incident response permissions |
| `maintainer` | trust-bearing settings, revocation, policy changes |

Tier transitions must be recorded as governance events.

## Reputation Inputs

Reputation may consider:

- accepted verified work,
- clean failure handling,
- timely lease releases,
- low conflict/error rate,
- useful decomposition or evidence,
- policy-compliant PRs,
- incident-free operation.

Reputation must not override verifier results.

## Phase-2 enforcement (the fork onramp)

When this layer is built (evidence-gated on the ADR-070 metric, after ADR-068's
claimless onramp), two facts make a cheap first slice possible without standing up
a full identity service:

- **The enforcement chokepoint already exists.** The `fork-automerge-enabler`
  (ADR-068 / SPEC-068-A §6) is the single upstream gate every fork contribution
  passes through. The minimal ADR-054 slice extends its admissibility selector
  (`tools.repo.fork_automerge`) with per-owner open-PR caps, a denylist, trial vs
  trusted tiering, and an emergency pause — most of the abuse controls above,
  reusing Phase-1 infrastructure, before any lease (SPEC-053-A §8.2 / §8.4).
- **Reputation is derivable, not newly tracked.** "Accepted verified work" is
  already recorded as the `⟦Π:Provenance⟧{solver≜…}` of every merged
  `library/index` entry (ADR-023). Tier promotion (`trial → trusted`) can read
  that existing signal rather than maintain a parallel reputation store.

Identity stays bound to the GitHub account (today's de-facto boundary); the
`owner_id` is the accountable human/fleet behind it. This layer controls *access*;
the kernel still decides *correctness*.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Agent identity, quotas, and reputation spec | Specification | specs/SPEC-054-A-Agent-Identity-Quotas-And-Reputation.md |
| REF-2 | Volunteer-scale claim substrate | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-3 | Proof provenance and leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-4 | Verification Tiers and Auditability | Decision | ADR-052-Verification-Tiers-And-Auditability.md |
| REF-5 | Fork-Native Contribution Mode (the enforcement chokepoint) | Decision | ADR-068-Fork-Native-Contribution-Mode.md |
| REF-6 | Duplicate-Verifier-Waste Metric (the Phase-2 gate) | Decision | ADR-070-Duplicate-Verifier-Waste-Metric.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-15 |
