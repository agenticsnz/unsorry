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
decomposition lineage plus a complete provenance table at `docs/proofs-contributors-visualisation.md`, with a
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
proofs report unknown), and the `docs/proofs-contributors-visualisation.md` drift guard is not yet wired into
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
| Amended | unsorry maintainers | 2026-06-17 |

## Amendment (2026-06-17): hybrid clustering, expand-on-click, shared layout

**In the context of** the V1 decision to *omit* standalone goals from the diagram
(they "carry no lineage and belong in the table"), which — once the corpus grew to
762 goals with only ~56 in decomposition forests — meant the diagram silently
represented under 8% of the graph and read as if most goals were missing,
**we amend the diagram to a hybrid layout**: the decomposition forest is unchanged,
and the remaining standalone goals are folded into **one collapsed summary cluster
per status** (a stadium-shaped, status-coloured node `▸ <status> · <n>`), so every
goal is accounted for without drawing ~700 illegible isolated boxes. On the
interactive page a cluster **expands on click** (`toggleCluster`) into a status
subgraph of its individual, clickable goal nodes, and collapses again — the client
rebuilds the Mermaid source from the embedded model (`graph_payload.unconnected`),
and its collapsed output is byte-identical to the server-rendered initial diagram.
The static markdown shows the collapsed clusters (the full per-goal list stays in
the table). We also bring the proof-graph page into **visual parity** with the
home/leaderboard card (shared heading scale `text-5xl md:text-7xl` and section
inset `px-6 md:px-10`) and remove the redundant header "Contributor leaderboard"
cross-link (the shared top-nav already links it),
**accepting that** expanding a large cluster renders many nodes (opt-in, so the
default view stays light), and that the cluster logic is expressed twice — once in
Python for markdown, once in JS for the interactive page — guarded by a parity test
that asserts the two collapsed renderings match. The companion **sourcing
leaderboard** (ADR-060) is surfaced in the same release as a fourth view on
`docs/leaderboard.html`.
