# SPEC-032-A: Proof Graph Visualiser

Implements: [ADR-032](../ADR-032-Proof-Graph-Visualiser.md) · Status: Living · Updated: 2026-06-13

## Scope

A V1 visualiser of the swarm proof graph (issue #371). One generator,
`tools/visualiser`, mirroring the `tools.sourcing.targets_board` and
`tools.leaderboard` conventions (stdlib-only, deterministic, `--write` / `--check`
/ `--json` modes). No new data is introduced — the graph is assembled from the
existing AISP coordination records.

## Inputs

| Source | Provides |
|--------|----------|
| `goals/*.aisp` | node id (file stem), `status`, `difficulty` |
| `decompositions/*.aisp` | `parent`, decomposing `agent`, and `Σ:Subs` sub-goal ids — the **parent → sub-goal** lineage edges |
| `library/index/*.aisp` | recorded GitHub `solver`, `model`, header date (via `tools.leaderboard.generate.proofs`) |
| `proof-runs/*.aisp` | successful-run `solver`/`model`/date — fallback when the index carries none (failed runs are ignored) |
| `prove(…)` / `recompose(…)` git subjects | the solving **agent**, **PR**, and merge **date** (`git log`, ADR-026 per-goal PR convention) |

Parsing reuses `tools.gate_b.records.parse_record`. Sub-goal ids are read from the
`subᵢ≜⟨id≜…,sha≜…⟩` vectors. Edges whose endpoints are not real goals (stale
decompositions) are dropped.

### "Who solved it" precedence

- **agent / PR / date / merged-by** — from the `prove(<goal>): … by <agent> (#PR)`
  merge commit (the authoritative per-goal record); the merging GitHub user is the
  commit author (`%an`, name only — squash-merge sets author to the merger).
  Goals merged before that convention (early/batch proofs) carry none and report
  `—` (we deliberately do **not** attribute them to the author of a later batch
  commit such as a changelog roll).
- **GitHub solver** — the recorded AISP login (index, then a successful run) where
  present; otherwise the merging GitHub user from the prove commit. **model** —
  recorded provenance only. Never inferred from git authorship as a *solver* claim
  beyond the explicit merged-by fallback, and never guessed (ADR-023).

The git read (`parse_prove_log` is the pure, tested parser; `git_provenance`
the thin wrapper) is the generator's only impurity and degrades to empty outside
a checkout. Because `docs/graph.md` then tracks the proof-commit history, it must
be regenerated when proofs merge — as the targets board already is — before the
`--check` drift guard is wired into CI.

## Graph model

```text
Node  = { id, status, difficulty, solver?, date?, model?, agent?, pr? }
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
   solving **agent**, GitHub **solver / model**, **PR** (linked), proved-on date.
   `—` where unknown.

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
dropping, Mermaid classes/clicks/edges, table completeness, JSON shape,
`--write`/`--check`/mutual-exclusion behaviour, the pure `parse_prove_log`
agent/PR/date parser (newest-wins, non-prove subjects ignored), and graceful
degradation when the tree is not a git checkout.

## Deferred (Phase 2, issue #371)

* `docs/graph.html` — interactive page (mermaid.js) with a click-to-detail panel
  (status, difficulty, solver, model, attempts, solve time, PR link, Lean
  artifact), styled to integrate with the leaderboard (#270), consuming `--json`.
* Wiring `tools.visualiser --check` into a CI workflow — lands via a separate
  code-owner-reviewed PR (touches `.github/`, ADR-019).
