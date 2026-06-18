# SPEC-032-A: Proof Graph Visualiser

Implements: [ADR-032](../ADR-032-Proof-Graph-Visualiser.md) · Status: Living · Updated: 2026-06-17

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
a checkout. Because `docs/proofs-contributors-visualisation.md` then tracks the proof-commit history, it must
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

## Output: `docs/proofs-contributors-visualisation.md`

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

## Output: `docs/proofs-contributors-visualisation.html` (Phase 2)

A standalone interactive page generated from the same graph model:

* the Mermaid forest rendered by **mermaid.js** (CDN ESM module) with the per-node
  `click` rewired to a `call showDetail("<goal>")` JS callback (`securityLevel:
  loose`);
* a **detail panel** that, on node or row click, shows status, difficulty, agent,
  solver, model, PR link, proved-on date, and a link to the Lean statement;
* zoom in/out/reset over the scrollable diagram;
* a **filterable table** of every goal (free-text over id/agent/solver + a status
  selector), each row clickable;
* the full graph model embedded as inline JSON (`#graph-data`) — the single feed
  the panel/table read, ready for the leaderboard (#270) to share.

Self-contained except for the mermaid ESM module; the browser renders it, GitHub
shows source (view via Pages or locally).

## Modes

* default → markdown to stdout
* `--html [root]` → interactive HTML to stdout
* `--json [root]` → graph model as JSON
* `--write [root]` → write **both** `docs/proofs-contributors-visualisation.md` and `docs/proofs-contributors-visualisation.html`
  (creating `docs/` if absent)
* `--check [root]` → exit 1 if **either** artifact differs from a fresh render
* the modes are mutually exclusive (exit 2 otherwise)

## Tests

`tools/visualiser/tests/test_generate.py` builds a fixture AISP tree (no network)
and asserts: node assembly + provenance enrichment, decomposition edges, stale-edge
dropping, Mermaid classes/clicks/edges, table completeness, JSON shape, HTML render
(mermaid pre, `showDetail` callbacks, embedded-JSON validity, no unreplaced
placeholders), `--html`/`--write`/`--check`/mutual-exclusion behaviour (both
artifacts), the pure `parse_prove_log` agent/PR/date/merged-by parser, and graceful
degradation when the tree is not a git checkout.

## Staying current (CI)

`docs/proofs-contributors-visualisation.{md,html}` are kept up to date by the
`proofs-visualisation` workflow (`.github/workflows/proofs-visualisation.yml`).

The attribution is derived from the `prove(<goal>): … by <agent> (#PR)`
**squash-merge commit**, which exists only on `main` *after* a proof merges — so
a PR-time `--check` cannot include the goal a PR is about to prove (it would
spuriously redden the *next* PR). The workflow therefore runs **post-merge**: on
each push to `main` touching `goals/`, `library/`, `proof-runs/`,
`decompositions/`, or `tools/visualiser/`, it runs `--check`, and on drift
regenerates the outputs and commits them straight back to `main` as a single
docs-only `[skip ci]` commit (the standard generated-artifact exception — not a
human/agent change). The commit touches only `docs/`, outside the trigger paths,
so it does not re-fire; `[skip ci]` also short-circuits the unfiltered gates.
`workflow_dispatch` allows a manual refresh.

This needs the Actions token to be allowed to push to `main` (a code-owner
setting). A `GITHUB_TOKEN`-opened PR would *not* trigger the required checks, so
a plain auto-PR could never self-merge; if a direct push is undesirable, the
fallback is a PAT-driven refresh PR.

## Amendment (ADR-032 / 2026-06-17): hybrid clusters, expand-on-click, layout parity

### Standalone goals → status clusters (supersedes "omit standalone goals")

V1 drew only forest nodes. The diagram now also renders the standalone goals (no
decomposition lineage), grouped by status:

* `_unconnected_by_status(graph) → {status: [Node]}` — goals not in any edge,
  grouped, **legend order** (`_ORDER`), ids sorted. Deterministic.
* `_mermaid_body` appends, after the forest, one **collapsed cluster** per status:
  a stadium node `_cluster_key(status)` = `cluster_<status>`, labelled
  `<status> · <count>` (HTML prefixes a `▸` caret), classed by status colour. In
  HTML the cluster carries `click … call toggleCluster("<status>")`; markdown
  clusters are non-interactive (the per-goal list is the table).
* `graph_payload` gains `unconnected: [{status, ids}]` (same order) — the feed the
  interactive page expands from. `--json` emits it; the model stays `{source,
  nodes, edges, unconnected}`.

### Expand-on-click (HTML)

The server-rendered `<pre class="mermaid">` paints the initial **collapsed** diagram
(and is the no-JS fallback). `buildMermaidSource(expanded)` in the page mirrors
`_mermaid_body` and, for a status in the `expanded` set, emits a `subgraph` of that
cluster's individual goal nodes (each `click … call showDetail`) plus a `▾` header
node that collapses it; `toggleCluster(status)` flips membership and re-renders via
`mermaid.render(...)` + `bindFunctions`. **Invariant (tested):** the JS
`buildMermaidSource(∅)` output is byte-identical to `_mermaid_body(for_html=True)`,
so collapsing always returns to the exact initial view.

### Layout parity

The proof-graph page shares the home/leaderboard card: heading `text-5xl md:text-7xl`
and section inset `px-6 md:px-10` (was `text-4xl md:text-6xl` / `md:px-8`), and the
redundant header "Contributor leaderboard" cross-link is removed — the shared
top-nav already links it.

### Sourcing view (ADR-060 surface)

`docs/leaderboard.html` (the hand-authored browser surface, not generated) gains a
fourth toggle **Sourcing** view that lazily fetches `docs/metrics/sourcing-leaderboard.json`
(`tools.leaderboard --sourcing`, schema_version 1) and renders the per-sourcer bars
ranked by `sourced_goals` with a proved/open/difficulty subline.

### Tests (added)

`test_unconnected_clusters_in_json`, `test_render_html_hybrid_clusters_expand`
(collapsed cluster + `buildMermaidSource`/`toggleCluster`/`subgraph` machinery +
embedded `unconnected`), `test_render_html_layout_parity`, the extended
`test_mermaid_has_classes_clicks_edges`, and (leaderboard suite) the extended
`test_docs_leaderboard_html_consumes_generated_ui_json` asserting the Sourcing
tab/view/`renderSourcing`/JSON wiring.
