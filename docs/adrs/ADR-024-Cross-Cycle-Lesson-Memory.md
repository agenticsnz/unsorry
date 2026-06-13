# ADR-024: Cross-Cycle Lesson Memory

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-024 |
| **Initiative** | distributed proof-work learning |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-13 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a distributed swarm whose every prove cycle starts from a fresh worktree and a stateless provider call, where ADR-023 already records append-only terminal proof-run facts (proved, decomposed, failed) but only as quantitative metrics, and whose coordination pattern is intended to generalise into a reusable substrate for crowdsourced problem solving,
**facing** the reality that a goal is re-attempted across cycles and across agents — after an affinity demotion, after a decomposition re-opens its parent, or simply by a different contributor — with no memory of *why* earlier efforts failed, so the swarm repeatedly spends its attempt budget rediscovering the same dead ends,
**we decided for** enriching the ADR-023 terminal proof-run record with an optional, bounded, single-line failure *signature* (`⟦Δ:Lesson⟧{sig≜…}`) distilled from the final failed attempt's local verifier output, plus a `⟦Λ:Metrics⟧` `lessons≜<n>` field counting how many prior lessons were injected into that run, and for surfacing a goal's prior failed and decomposed lesson signatures into the prove prompt the same way ADR-014 surfaces proved dependencies — all behind a single `UNSORRY_LESSONS` toggle (default on) whose off-state is byte-identical to pre-feature behaviour,
**and neglected** storing full per-attempt transcripts (unbounded, noisy, and a poor fit for the trust-clean `main` history), a parallel lesson store on the `claims` branch (it would split telemetry away from the run facts and stretch ADR-004's claims-only scope), free-text or quoted-prose lessons (they violate the AISP block grammar and trip the Gate B GB009 prose-density lint), and any path that lets a lesson influence proof admission, Gate A, affinity, or candidate ranking (self-reported signals must never become a trust input, per ADR-023),
**to achieve** cross-cycle and cross-agent learning that steers a re-attempt away from a previously observed failure, a measurable lever (`lessons≜<n>` correlated with outcome) for deciding whether shared learning actually saves work, and a reusable failure-accounting pattern for crowdsourced problem solving beyond Lean,
**accepting that** a one-line signature is lossy relative to a full trace, lessons are contributor-reported and remain advisory, identical signatures are de-duplicated but semantically near-miss failures are not clustered, the lesson corpus grows with the set of attempted goals (bounded per record and capped per prompt, but not garbage-collected when a goal is later proved), and the benefit of the feature is unproven until the `lessons≜<n>` telemetry is analysed.

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Cross-cycle lesson memory specification | Specification | specs/SPEC-024-A-Cross-Cycle-Lesson-Memory.md |
| REF-2 | Proof provenance and leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-3 | Dependency reuse | Decision | ADR-014 (proved-dependency surfacing) |
| REF-4 | Infrastructure-failure guard | Decision | ADR-016 (excluded from lessons) |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-13 |
| Accepted | unsorry maintainers | 2026-06-13 |
