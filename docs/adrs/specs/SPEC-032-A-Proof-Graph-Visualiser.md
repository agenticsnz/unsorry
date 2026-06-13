# SPEC-032-A: Proof Graph Visualiser

Implements: [ADR-032](../ADR-032-Proof-Graph-Visualiser.md) · Status: Living · Updated: 2026-06-13

## Scope

A V1 visualiser of the swarm proof graph (issue #371). One generator,
`tools/visualiser`, mirroring the `tools.sourcing.targets_board` and
`tools.leaderboard` conventions (stdlib-only, deterministic, `--write` / `--check`
/ `--json` modes). No new data is introduced — the graph is assembled from the
existing AISP coordination records.

## Inputs (pure, no git)

| Record | Provides |
|--------|----------|
| `goals/*.aisp` | node id (file stem), `status`, `difficulty` |
| `decompositions/*.aisp` | `parent`, decomposing `agent`, and `Σ:Subs` sub-goal ids — the **parent → sub-goal** lineage edges |
| `library/index/*.aisp` | per-goal provenance (`solver`, `model`, header date) via `tools.leaderboard.generate.proofs` |
| `proof-runs/*.aisp` | richer run telemetry, reused through the leaderboard loader |

Parsing reuses `tools.gate_b.records.parse_record`. Sub-goal ids are read from the
`subᵢ≜⟨id≜…,sha≜…⟩` vectors. Edges whose endpoints are not real goals (stale
decompositions) are dropped.

## Graph model

```text
Node  = { id, status, difficulty, solver?, date?, model? }
Edge  = { parent, child, agent? }     # parent → sub-goal
Graph = { nodes, edges }
```

`--json` emits `{ source, nodes, edges }` for Phase-2 consumers (the interactive
HTML page and the leaderboard) to share one feed.

## Output: `docs/graph.md`

1. **Header + summary** — total goals and per-status counts.
2. **Dependency lineage** — a fenced ```` ```mermaid ```` `flowchart LR`:
   * one node per goal **that participates in a decomposition** (standalone goals
     carry no lineage and live in the table, keeping the diagram legible);
   * `classDef` per status (`proved`/`open`/`blocked`/`flagged`/`translated`) for
     colour;
   * a `click` directive per node linking to its Lean statement on `main`.
3. **Legend.**
4. **All goals** — a table of every goal: id (linked), status, difficulty,
   solver/model, proved-on date. `—` where provenance is unknown.

Node keys are sanitised (`g_` + `[^0-9a-z]→_`) because goal ids carry hyphens.

## Modes

* default → markdown to stdout
* `--write [root]` → write `docs/graph.md` (creating `docs/` if absent)
* `--check [root]` → exit 1 if `docs/graph.md` differs from a fresh render
* `--json [root]` → graph model as JSON
* the three modes are mutually exclusive (exit 2 otherwise)

## Tests

`tools/visualiser/tests/test_generate.py` builds a fixture AISP tree (no network)
and asserts: node assembly + provenance enrichment, decomposition edges, stale-edge
dropping, Mermaid classes/clicks/edges, table completeness, JSON shape, and
`--write`/`--check`/mutual-exclusion behaviour.

## Deferred (Phase 2, issue #371)

* `docs/graph.html` — interactive page (mermaid.js) with a click-to-detail panel
  (status, difficulty, solver, model, attempts, solve time, PR link, Lean
  artifact), styled to integrate with the leaderboard (#270), consuming `--json`.
* Wiring `tools.visualiser --check` into a CI workflow — lands via a separate
  code-owner-reviewed PR (touches `.github/`, ADR-019).
