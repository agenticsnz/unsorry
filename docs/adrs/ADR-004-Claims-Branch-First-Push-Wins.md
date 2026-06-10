# ADR-004: Claims on a Dedicated Branch, First-Push-Wins

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-004 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** the unsorry swarm using the git repository as its only coordination infrastructure, where agents claim open goals by pushing claim files and a rejected push means another agent won the race,
**facing** a structural incompatibility between atomic claim pushes and a protected `main` branch — `main` carries required status checks (Gates A and B) and the adopted protocols forbid direct commits to it, so the design doc's "push a claim file; first push wins" cannot operate on `main`,
**we decided for** a dedicated, unprotected git branch named `claims`: an agent claims a goal by pushing `claims/<goal-id>.<agent-id>.aisp` to that branch, with git's atomic non-fast-forward rejection providing first-push-wins semantics, and a scheduled reaper job removing expired (TTL-elapsed) claims on the same branch,
**and neglected** claims on `main` behind a path-scoped push ruleset (fragile, under-documented GitHub behaviour; recorded as the fallback), claims as pull requests (destroys atomicity and spams CI), and an external queue or database service (violates the repository-is-the-only-infrastructure principle),
**to achieve** the design doc's git-native atomic claiming, intact branch protection and soundness gates on `main`, and zero per-claim CI cost,
**accepting that** claims state lives on a branch contributors must know to fetch (`agent.sh` handles it), the branch's history grows and is periodically squashed since claims are ephemeral, and the branch is unprotected by design — its integrity is a hygiene concern, never a soundness concern.

## Context

The design doc and README define the claim mechanism that makes distributed goal selection safe without a queue server: an agent claims a goal by pushing a claim file (`claims/<goal-id>.<agent-id>.aisp`, carrying a timestamp and TTL), and "first push wins" — a rejected push means another agent claimed first, so the agent picks a different goal. This relies on a property git provides for free: a push to a branch is atomic, and a non-fast-forward push is rejected. Two agents racing to claim the same goal cannot both succeed.

This mechanism collides with the development protocols adopted in ADR-001. `main` carries branch protection with required status checks — Gate A (soundness) and Gate B (coordination hygiene) — and the protocols forbid direct commits to `main` entirely; all changes arrive by reviewed-and-gated pull request. Atomic direct pushes and a protected branch are structurally incompatible on the same ref. If claims travelled by PR instead, the race would be decided by merge order rather than push order, queue latency would replace atomicity, and every claim would trigger a CI run — three properties the design explicitly avoids.

The resolution is to separate the two concerns onto two branches. The verified library and all gated content stay on protected `main`. Claims live on a dedicated, deliberately unprotected branch named `claims`. The claim protocol on that branch is: push the claim file; if the push is rejected, fetch and rebase; if a competing claim for the same goal now exists, log a collision and select another goal; otherwise push again. A scheduled reaper job removes expired claims from the same branch, implementing the stale-claim expiry the design doc requires so a dead agent cannot park a goal forever. `main` carries a `claims/README.md` documenting the mechanism so the branch is discoverable.

This split is sound because claims are pure coordination state. Gate B, which validates claim files, is advisory and can never admit anything into the library; only Gate A does that. Losing or corrupting the entire `claims` branch could waste agent effort through duplicated work, but it cannot affect a single verified proof. The unprotected branch therefore weakens nothing that the architecture treats as load-bearing.

## Options Considered

### Option 1: Dedicated unprotected `claims` branch (Selected)
Pros: preserves the design doc's first-push-wins atomicity exactly as written, using only git semantics; `main`'s branch protection and required gates remain fully intact; claims cost no CI runs; the repository remains the only infrastructure. Cons: coordination state is split across two branches, so agents and humans must fetch `claims` to see the queue's claim state (handled by `agent.sh`); branch history grows with churn (mitigated by periodic squashing, which is safe because claims are ephemeral); the branch has no protection, so its integrity rests on contributor hygiene — acceptable because Gate B validates claim content and nothing on the branch is soundness-relevant.

### Option 2: Claims on `main` behind a path-scoped push ruleset (Rejected)
GitHub rulesets can in principle scope push restrictions by path, which might allow direct pushes touching only `claims/` while keeping the rest of `main` protected. However, ruleset behaviour for path-scoped direct-push exceptions coexisting with required status checks is fragile and under-documented, and a misconfiguration would either silently open `main` to direct pushes or silently break claiming. Rejected for now; recorded here as the fallback, to be revisited only with a live behavioural test if the dedicated branch proves problematic.

### Option 3: Claims as pull requests (Rejected)
Routing claims through PRs onto protected `main` destroys the property the mechanism exists for. PR merges are not atomic with respect to each other — two claims for the same goal can both pass checks before either merges — so first-push-wins degrades into a merge-order race needing extra arbitration. Merge-queue latency would sit inside every claim, and each claim would trigger a full CI run, multiplying CI cost by the claim rate (including collisions). Rejected outright.

### Option 4: External queue or database service (Rejected)
A coordination service (queue server, database, lock service) would make claiming trivial but violates the design principle that the repository is the only infrastructure — no queue server, no database, no central judge. It adds an availability dependency, an operational burden, and a second source of truth that can drift from the repo. Rejected as contrary to the architecture's stated foundations.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-003 | AISP Coordination Format with In-Repo Validation | Claim files are AISP artifacts; Gate B validates their form and freshness |
| Relates To | ADR-005 | Autonomous Merge Policy | The merge policy assumes the claim and collision semantics defined here |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Distributed Autonomous Research Swarm: Architecture and Plan | Design document | docs/proposals/distributed-research-swarm-plan.md |
| REF-2 | unsorry README — claim semantics in "How the loop works" and "Contributing" | Project document | README.md |
| REF-3 | Development protocols (feature branches, no direct commits to main) | Protocol document | docs/protocols.md |
| REF-4 | SPEC-004-A — Claims Branch Mechanics and Reaper | Specification | docs/adrs/specs/ (lands with its implementation PR) |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
