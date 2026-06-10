# ADR-007: Agent Identity and Budgets

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-007 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** the swarm's agent loop (`swarm/agent.sh`), where heterogeneous contributors run Claude Code headless against the shared repository and the coordination layer must tell agents apart without any registration service,
**facing** the need for a stable per-machine agent identity, enforceable work budgets, and an invocation mode that works for ordinary contributors — who run Claude subscriptions, not API keys,
**we decided for** self-assigned agent identities (`AGENT_ID = <short-hostname>-<4 hex>`, persisted at `~/.unsorry/agent-id`) carried in claim and translation records, with the contributor's own GitHub account as the transport identity; budgets enforced by the loop script (`--max-turns` per claude call, wall-clock `timeout`, attempt cap, all mirroring `swarm/protocol.aisp`); and headless invocation via the contributor's existing `claude` authentication (subscription or API key alike, no `ANTHROPIC_API_KEY` requirement),
**and neglected** GitHub machine accounts per agent, a central identity registry, and API-key-only invocation,
**to achieve** zero-friction onboarding (clone, run, done), swarm-level identity that survives across sessions, and coordination records that distinguish concurrent agents on the same GitHub account,
**accepting that** agent ids are self-asserted and not cryptographically bound to anything (acceptable: identity is hygiene, never soundness — Gate A re-verifies all content regardless of who pushed it), and that PRs from agents on one machine share that machine's GitHub identity (recorded honestly in evidence files; from 2026-06-15 headless subscription runs draw Agent SDK credits per Anthropic's pricing).

## Context

The design doc's contributor model is anonymous-by-architecture: the kernel re-verifies everything, so the system never needs to trust an identity. Identity exists only for coordination — claim files must say who holds them so TTL reaping and collision handling work, and translation records must say who translated so the dual-translation gate can require two *distinct* agents.

A registration service would violate "the repository is the only infrastructure". A GitHub machine account per agent is heavyweight for contributors and unnecessary: the agent id, not the GitHub account, is the coordination identity. The readiness checklist's "non-author agent merges a proof end-to-end" is evidenced by a distinct AGENT_ID running from a fresh clone with no knowledge of seed commits — with the honest caveat, recorded in the evidence file, that the GitHub author field shows the machine owner's account.

Budgets exist so a stuck agent cannot burn unbounded tokens or hold claims forever: the loop enforces per-call turn caps, a wall-clock timeout, and an attempt cap, then releases its claim and exits. The TTL covers the crash case.

## Options Considered

### Option 1: Self-assigned persisted AGENT_ID + own-account transport + script-enforced budgets (Selected)
Pros: no infrastructure, no onboarding friction, works for subscription users, ids stable across sessions, concurrent agents on one machine distinguishable (one id per `~/.unsorry`, overridable via `UNSORRY_AGENT_ID` for trials). Cons: ids are self-asserted (spoofable — harmless, since nothing trust-bearing reads them); GitHub author ≠ agent id.

### Option 2: GitHub machine account per agent (Rejected)
Stronger author-field evidence, but heavyweight per-contributor setup (account + PAT minting), contradicts zero-friction onboarding, and adds nothing to soundness — the kernel does not care who pushed. Reconsider for the public-evidence story post-1.0 if wanted.

### Option 3: Central identity registry (Rejected)
A registration file or service reintroduces coordination state outside the artifacts themselves and violates the repository-only-infrastructure principle for no hygiene gain.

### Option 4: Require ANTHROPIC_API_KEY (Rejected)
Contributors run subscriptions. Requiring API-key billing would shrink the contributor pool to exactly the people the project least needs to recruit. The script uses whatever `claude` auth is present.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-001 | Adopt Development Protocols | Process governing this decision |
| Depends On | ADR-004 | Claims on a Dedicated Branch, First-Push-Wins | Claims carry the agent id this ADR defines |
| Relates To | ADR-003 | AISP Coordination Format | Identity fields live in AISP records |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-007-A — Agent Loop Script | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |
| REF-2 | swarm/protocol.aisp ⟦Λ:Loop⟧ budgets | Contract | ../../swarm/protocol.aisp |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
