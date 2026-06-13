# ADR-032: Proof Graph Visualiser

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-032 |
| **Initiative** | proof-graph visualisation (issue #371) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-13 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a swarm whose proof graph — every goal, its status, the
decomposition lineage that stacks sub-goals into their parents, and who solved
each one — is already recorded across the AISP coordination records but is not
viewable as a graph,
**facing** issue #371's need for an attractive, clickable visualisation of all
proofs and unsolved targets and how they interrelate, that stays consistent with
the leaderboard (#270) and surfaces the full step ladder behind big targets such
as Freek #50 (#365),
**we decided for** a generated visualiser tool (`tools/visualiser`) that is pure
over the in-repo records (`goals/`, `decompositions/`, `library/index/`,
`proof-runs/`) and emits, in V1, a GitHub-native Mermaid `flowchart` of the
decomposition lineage plus a complete provenance table at `docs/graph.md`, with a
machine-readable `--json` graph model that a later interactive HTML surface and
the leaderboard can share, gated for drift by a `--check` mode,
**and neglected** shelling out to git for provenance (non-deterministic, would
break `--check`), re-deriving provenance instead of reusing
`tools.leaderboard.generate`, drawing all standalone goals as isolated graph nodes
(illegible — they carry no lineage and belong in the table), and building the
interactive HTML in the same step (deferred to a Phase-2 PR that consumes the
`--json` feed),
**to achieve** a durable, regenerable picture of the proof graph that reuses the
existing parsers (`tools.gate_b.records`, `tools.leaderboard`), renders with zero
JavaScript in the README, and serves as the shared data source for the leaderboard
and the Freek-50 step ladder,
**accepting that** V1 is static markdown (no in-page click-to-detail panel until
Phase 2), goal provenance is only as complete as the index/run records (older
proofs report unknown), and the `docs/graph.md` drift guard is not yet wired into
CI because that touches the CODEOWNERS-protected `.github/` surface (ADR-019) and
lands via a separate code-owner-reviewed PR.

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Proof graph visualiser specification | Specification | specs/SPEC-032-A-Proof-Graph-Visualiser.md |
| REF-2 | Proof provenance and leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-3 | Freek #50 Platonic solids roadmap | Decision | ADR-031-Freek-50-Platonic-Solids-Roadmap.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-13 |
