# ADR-005: Autonomous Merge Policy

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-005 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a distributed swarm of autonomous agents contributing kernel-verified Lean 4 proofs to a shared library through pull requests, where the design contract is that agents and humans contribute identically and the gates decide,
**facing** the need for a merge path that runs unattended at swarm cadence without weakening the central claim that the Lean kernel — not human goodwill — protects the library,
**we decided for** autonomous merging: branch protection on `main` requires Gate A (soundness: `lake build --wfail`, axiom audit, `leanchecker`) and Gate B (hygiene: the in-repo AISP validator) as required status checks with no required human reviewers, and contributors enable auto-merge (`gh pr merge --auto --squash`) so the merge happens the moment checks go green,
**and neglected** required human review on every PR, a GitHub merge queue, and operating with no branch protection at all,
**to achieve** unattended swarm throughput, identical treatment of agent and human contributions, and a merge gate whose authority rests entirely on machine verification,
**accepting that** a kernel-valid but poorly named or duplicative contribution can merge without human eyes (hygiene issues are cleaned up post-merge by design), and that the required-check configuration must be kept in lockstep with CI workflow job names, since a renamed job would block all merges.

## Context

The design document's contributor model is explicit: agents and humans contribute the same way — claim a goal, open a PR, and let the gates decide. Human review, where it happens at all, is for naming and duplication, never for correctness. The entire architecture exists to make untrusted contributions safe: Gate A re-verifies every contribution against the Lean kernel, which decides correctness deterministically. A proof compiles or it does not, and a careless or even adversarial contributor cannot poison the library.

This makes the merge policy a direct consequence of the architecture rather than an operational convenience. Requiring a human approval on every PR would reintroduce the human as a correctness oracle — a false one, since no reviewer can check a proof better than the kernel that has already checked it — and would make a single person's availability the throughput ceiling of a swarm designed to run unattended. The merge mechanics must therefore be fully automatic on the green path.

At the same time, the green path must be the only path. Branch protection on `main` exists so that nothing reaches the library without passing Gate A; an unprotected default branch would let a direct push bypass the soundness gate entirely. Admin bypass of the protection rules is retained strictly for emergencies (for example, unblocking a misconfigured required check) and is never used as a normal contribution path. Routinely bypassing the gates would destroy the meaning of the project's central claim: that the kernel, not goodwill, protects the library.

Gate B participates as a required check alongside Gate A, but the asymmetry established in the design document is unchanged: Gate B keeps the queue clean and can never admit anything into the library. A coordination artifact passing Gate B says nothing about mathematical truth; only Gate A guards soundness.

## Options Considered

### Option 1: Autonomous merge on required status checks, no required reviewers (Selected)
Branch protection on `main` lists Gate A and Gate B as required status checks and zero required human reviewers. Contributors — agent or human — enable auto-merge with squash; GitHub completes the merge when the checks pass.
**Pros:** the merge decision rests entirely on the kernel and the deterministic validator, matching the architecture's trust model; the swarm runs unattended with no human bottleneck; agents and humans go through an identical path; squash merges keep `main` history one-commit-per-contribution.
**Cons:** kernel-valid but hygienically poor contributions (bad naming, duplication) merge without human eyes; the required-check list is configuration that must track CI job names exactly.

### Option 2: Required human review on every PR (Rejected)
Contradicts the design document's contributor model directly. It bottlenecks the swarm on reviewer availability, and it implies that a human is vouching for correctness they cannot evaluate better than the kernel — precisely the false oracle the architecture was built to remove. Human attention is reserved for flagged statement-fidelity mismatches and post-merge hygiene, where it actually adds value.

### Option 3: GitHub merge queue (Rejected)
Unnecessary at current volume. Index entries are content-addressed, one file per lemma, so concurrent PRs are textually conflict-free and do not race each other in ways a queue would resolve. A merge queue adds configuration and latency without buying anything today. Revisit in Phase 2 if contribution volume produces real merge contention.

### Option 4: No branch protection at all (Rejected)
Auto-merge does not require branch protection mechanically, but without it a direct push to `main` bypasses Gate A entirely. One accidental or malicious unverified push would break the invariant that everything in the library has been kernel-checked in CI. The protection rule is what turns "the kernel is the only truth oracle" from a habit into an enforced property.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-001 | Adopt Development Protocols | Establishes the ADR/spec/CI discipline this policy is expressed and enforced under |
| Depends On | ADR-004 | Claims on a Dedicated Branch, First-Push-Wins | Claim coordination keeps concurrent PRs non-overlapping, making reviewer-less auto-merge safe at the queue level |
| Relates To | ADR-002 | Lean 4 + mathlib4 Pinned to Release Tags | Pinned toolchain versions make Gate A's verdict reproducible, which the autonomous merge relies on |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Distributed Autonomous Research Swarm: Architecture and Plan | Design document | docs/proposals/distributed-research-swarm-plan.md |
| REF-2 | unsorry README — contributor model and CI gates | Project documentation | README.md |
| REF-3 | SPEC-005-A — Branch protection and auto-merge configuration | Specification (planned) | docs/adrs/specs/ — lands with its implementation PR |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
