# ADR-023: Optional Proof Provenance and Leaderboard

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-023 |
| **Initiative** | distributed proof-work attribution |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-13 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a distributed swarm whose verified outputs may be produced by different people, machines, providers, and models, and whose coordination pattern may later generalise beyond theorem proving,
**facing** the need to credit contributors and measure which tools produce useful verified work without rewriting or guessing the provenance of historical proofs,
**we decided for** optional proof provenance stored beside each successful content-addressed library index entry, plus append-only terminal proof-run facts for proved, decomposed, and failed outcomes, recording the GitHub solver, swarm agent, provider, effective model when known, final effort, attempts, completion time, and local solve duration, with deterministic machine-readable base statistics and leaderboard views,
**and neglected** Git commit authorship (squash and auto-merge identify the merger rather than reliably identifying the solver), mandatory backfilling (historical data is incomplete), infrastructure outages as model failures, and using leaderboard values in proof admission or work selection (self-reported metadata must not become a trust input),
**to achieve** durable attribution, honest success/failure denominators, effort recognition, provider/model and difficulty efficiency analysis, and a reusable distributed-work accounting layer,
**accepting that** early proofs and failures remain historical/unknown, timing currently measures local proof generation plus verification rather than CI or wall-clock claim latency, telemetry is contributor-reported, terminal records do not preserve every attempt's full trace or token/cost/energy data, and small observational samples cannot establish causal model superiority.

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Proof provenance and leaderboard specification | Specification | specs/SPEC-023-A-Proof-Provenance-Leaderboard.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-13 |
