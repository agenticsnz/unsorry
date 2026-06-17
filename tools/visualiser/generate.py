"""Generate the proof-graph visualiser (issue #371, ADR-032).

A V1 visualiser for the swarm's proof graph: every prove-goal as a node coloured
by status, the decomposition lineage as edges (parent → sub-goal), and a complete
provenance table (who solved each goal, when, with which model). The diagram is a
GitHub-native Mermaid ``flowchart`` so it renders in the browser with zero
JavaScript; the interactive HTML surface (issue #371, Phase 2) consumes the same
``--json`` model.

The generator reads the in-repo AISP coordination records (``goals/``,
``decompositions/``, ``library/index/``, ``proof-runs/``) for the graph and the
recorded GitHub-solver/model provenance, and additionally resolves the solving
**agent** and **PR** for each goal from the ``prove(…)`` / ``recompose(…)``
squash-merge subjects (the per-goal PR convention, ADR-026). The git read is the
only impurity and degrades to empty outside a checkout; because the outputs then
track the proof-commit history they must be regenerated when proofs merge (as the
targets board is) before ``--check`` is gated in CI.

Usage::

    python3 -m tools.visualiser [<repo-root>]            # markdown to stdout
    python3 -m tools.visualiser --json [<repo-root>]     # graph model as JSON
    python3 -m tools.visualiser --html [<repo-root>]     # interactive HTML to stdout
    python3 -m tools.visualiser --svg [<repo-root>]      # README preview SVG to stdout
    python3 -m tools.visualiser --write [<repo-root>]    # write the docs/*.{md,html,svg} set
    python3 -m tools.visualiser --check [<repo-root>]    # CI drift check (all three)
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

from tools.gate_b.records import parse_record
from tools.leaderboard.generate import goals as _goals
from tools.leaderboard.generate import proofs as _proofs
from tools.leaderboard.generate import runs as _runs

#: GitHub blob base for click-through links (goal statements live on ``main``).
BLOB_BASE = "https://github.com/agenticsnz/unsorry/blob/main"

#: Status → (Mermaid class name, swatch) for the legend and node styling.
STATUS_STYLE: dict[str, tuple[str, str]] = {
    "proved": ("proved", "#c6f6d5"),
    "open": ("open", "#e2e8f0"),
    "blocked": ("blocked", "#feebc8"),
    "flagged": ("flagged", "#fed7d7"),
    "translated": ("translated", "#bee3f8"),
}
_DEFAULT_STYLE = ("unknown", "#edf2f7")

#: Render order for status groupings (proved last so the eye lands on the work).
_ORDER = {"open": 0, "blocked": 1, "flagged": 2, "translated": 3, "proved": 4}

#: GitHub PR base for click-through links.
PR_BASE = "https://github.com/agenticsnz/unsorry/pull"

#: Output filenames under ``docs/`` (markdown for GitHub, HTML for the browser,
#: SVG for the README preview card — the leaderboard's two-surface pattern, ADR-038).
MD_NAME = "proofs-contributors-visualisation.md"
HTML_NAME = "proofs-contributors-visualisation.html"
SVG_NAME = "proof-graph.svg"

_SUB_ID_RE = re.compile(r"id≜([a-z0-9][a-z0-9-]*)")

#: Squash-merge subject for a proof on `main`, e.g.
#: ``prove(cube-eq-triangular-sq-diff): cube_eq_triangular_sq_diff by claude-rmt-001 (#322)``.
#: ``recompose`` is the assembly verb behind a decomposed parent.
_PROVE_SUBJECT_RE = re.compile(
    r"^(?:prove|recompose)\((?P<goal>[a-z0-9][a-z0-9-]*)\):\s+\S+\s+by\s+"
    r"(?P<agent>[a-z0-9][a-z0-9-]*)\s+\(#(?P<pr>\d+)\)"
)


@dataclass(frozen=True)
class Node:
    id: str
    status: str
    difficulty: int
    solver: str | None
    date: str | None
    model: str | None
    agent: str | None = None
    pr: str | None = None


@dataclass(frozen=True)
class Edge:
    parent: str
    child: str
    agent: str | None


@dataclass(frozen=True)
class Graph:
    nodes: tuple[Node, ...]
    edges: tuple[Edge, ...]


def _decomposition_edges(root: Path) -> list[Edge]:
    """Parent → sub-goal lineage edges, parsed from ``decompositions/*.aisp``."""
    edges: list[Edge] = []
    decomp_dir = root / "decompositions"
    if not decomp_dir.is_dir():
        return edges
    for path in sorted(decomp_dir.glob("*.aisp")):
        record = parse_record(path.read_text(encoding="utf-8"))
        parent = record.fields.get("parent")
        if not parent:
            continue
        agent = record.fields.get("agent")
        for key, value in record.fields.items():
            if not key.startswith("sub"):
                continue
            match = _SUB_ID_RE.search(value)
            if match:
                edges.append(Edge(parent=parent, child=match.group(1), agent=agent))
    return edges


@dataclass(frozen=True)
class ProveCommit:
    agent: str
    pr: str
    date: str | None
    #: Display name of the commit author — the GitHub user who merged the PR
    #: (squash-merge sets author to the merger; the committer is always GitHub).
    merged_by: str | None


def parse_prove_log(text: str) -> dict[str, ProveCommit]:
    """Map goal → :class:`ProveCommit` from ``git log`` ``date\\0author\\0subject`` lines.

    The newest (first) ``prove(<goal>): … by <agent> (#PR)`` wins per goal — the
    merge that flipped it to proved. Pure and testable; no git access here.
    """
    result: dict[str, ProveCommit] = {}
    for line in text.splitlines():
        date, _, rest = line.partition("\x00")
        author, _, subject = rest.partition("\x00")
        match = _PROVE_SUBJECT_RE.match(subject)
        if match:
            result.setdefault(
                match.group("goal"),
                ProveCommit(
                    agent=match.group("agent"),
                    pr=match.group("pr"),
                    date=date or None,
                    merged_by=author or None,
                ),
            )
    return result


def git_provenance(root: Path) -> dict[str, ProveCommit]:
    """Resolve goal → :class:`ProveCommit` from the proof commits on the branch.

    Reads the ``prove(...)`` / ``recompose(...)`` squash-merge subjects — the
    authoritative record of *which agent* proved each goal via *which PR*, and of
    *which GitHub user* merged it (the commit author; ADR-026). Degrades to
    ``{}`` outside a git checkout so the AISP-only path (and the fixture tests)
    stay green.
    """
    try:
        proc = subprocess.run(
            ["git", "-C", str(root), "log", "--no-merges", "--format=%cs%x00%an%x00%s"],
            capture_output=True,
            text=True,
            check=False,
        )
    except (OSError, ValueError):
        return {}
    if proc.returncode != 0:
        return {}
    return parse_prove_log(proc.stdout)


def build_graph(root: Path) -> Graph:
    """Assemble the proof graph from the AISP records and the proof commits.

    "Who solved it" is resolved with a clear precedence: the solving **agent**,
    **PR**, and merge **date** come from the ``prove(...)`` commit (ADR-026);
    the GitHub **solver** and **model** come from the AISP provenance — the
    content-addressed ``library/index`` record (preferred), falling back to a
    successful ``proof-runs`` record. Anything not recorded stays unknown; the
    generator never guesses (ADR-023).
    """
    goal_records = _goals(root)
    git_prov = git_provenance(root)
    by_goal = {proof.goal: proof for proof in _proofs(root, goal_records)}
    # Fallback: the best proved terminal run per goal (first wins; runs are sorted).
    by_run: dict[str, object] = {}
    for run in _runs(root, goal_records):
        if run.outcome == "proved" and run.solver and run.solver != "unknown":
            by_run.setdefault(run.goal, run)

    def _prov(gid: str) -> tuple[str | None, str | None, str | None]:
        """(solver, model, date) preferring the index, falling back to a run."""
        idx = by_goal.get(gid)
        solver = idx.solver if idx else None
        model = idx.model if idx else None
        date = (idx.date or None) if idx else None
        if solver is None and (run := by_run.get(gid)) is not None:
            solver = run.solver
            model = run.model
            date = date or (run.ended[:10] if run.ended else None)
        return solver, model, date

    def _node(goal) -> Node:
        solver, model, aisp_date = _prov(goal.id)
        commit = git_prov.get(goal.id)
        # Fill the solver gap with the GitHub user who merged the prove PR; keep
        # an explicitly recorded AISP solver where present. Goals with no
        # prove-PR (pre-convention) keep solver unknown.
        if solver is None and commit is not None:
            solver = commit.merged_by
        return Node(
            id=goal.id,
            status=goal.status,
            difficulty=goal.difficulty,
            solver=solver,
            model=model,
            date=(commit.date if commit else None) or aisp_date,
            agent=commit.agent if commit else None,
            pr=commit.pr if commit else None,
        )

    nodes = tuple(_node(goal) for goal in sorted(goal_records, key=lambda g: g.id))
    known = {node.id for node in nodes}
    edges = tuple(
        edge
        for edge in _decomposition_edges(root)
        # Keep only edges whose endpoints are real goals (skip stale decomps).
        if edge.parent in known and edge.child in known
    )
    return Graph(nodes=nodes, edges=edges)


def _node_key(goal_id: str) -> str:
    """Mermaid-safe node identifier (ids carry hyphens; node keys may not)."""
    return "g_" + re.sub(r"[^0-9a-z]", "_", goal_id)


def _status_class(status: str) -> str:
    return STATUS_STYLE.get(status, _DEFAULT_STYLE)[0]


def _unconnected_by_status(graph: Graph) -> dict[str, list[Node]]:
    """Standalone goals (no decomposition lineage) grouped by status.

    These carry no parent→sub edge, so they are not part of the forest. Rather
    than drop them (ADR-032 V1) or draw ~700 isolated boxes (illegible), the
    hybrid layout folds them into one summary **cluster** per status that the
    interactive page expands on demand. Groups are returned in legend order with
    ids sorted, so the rendering is deterministic.
    """
    in_forest = {edge.parent for edge in graph.edges} | {
        edge.child for edge in graph.edges
    }
    groups: dict[str, list[Node]] = {}
    for node in sorted(graph.nodes, key=lambda n: n.id):
        if node.id in in_forest:
            continue
        groups.setdefault(node.status, []).append(node)
    return {s: groups[s] for s in sorted(groups, key=lambda s: _ORDER.get(s, 9))}


def _cluster_key(status: str) -> str:
    """Mermaid-safe node id for a status cluster (distinct from ``g_`` goal keys)."""
    return "cluster_" + re.sub(r"[^0-9a-z]", "_", status)


def _mermaid_body(graph: Graph, *, for_html: bool) -> list[str]:
    """The ``flowchart`` definition lines (no code fence).

    ``for_html`` switches the per-node ``click`` from a GitHub URL (rendered
    natively in markdown) to a ``call showDetail("<goal>")`` JS callback (the
    interactive HTML detail panel).
    """
    in_forest = {edge.parent for edge in graph.edges} | {
        edge.child for edge in graph.edges
    }
    lines = ["flowchart LR"]
    for status, (cls, fill) in STATUS_STYLE.items():
        lines.append(f"  classDef {cls} fill:{fill},stroke:#4a5568,color:#1a202c;")
    lines.append(f"  classDef {_DEFAULT_STYLE[0]} fill:{_DEFAULT_STYLE[1]},stroke:#4a5568,color:#1a202c;")
    for node in graph.nodes:
        if node.id not in in_forest:
            continue
        key = _node_key(node.id)
        lines.append(f'  {key}["{node.id}"]')
        lines.append(f"  class {key} {_status_class(node.status)};")
        if for_html:
            lines.append(f'  click {key} call showDetail("{node.id}")')
        else:
            lines.append(
                f'  click {key} "{BLOB_BASE}/goals/{node.id}.lean" "{node.id} — {node.status}"'
            )
    for edge in sorted(graph.edges, key=lambda e: (e.parent, e.child)):
        lines.append(f"  {_node_key(edge.parent)} --> {_node_key(edge.child)}")
    # Standalone goals (no lineage) collapse into one stadium-shaped summary
    # cluster per status, status-coloured so the diagram still accounts for every
    # goal. The interactive HTML expands a cluster into its goals on click
    # (``toggleCluster``); the static markdown shows the collapsed summary and the
    # full per-goal list lives in the table below.
    for status, members in _unconnected_by_status(graph).items():
        ckey = _cluster_key(status)
        caret = "▸ " if for_html else ""
        lines.append(f'  {ckey}(["{caret}{status} · {len(members)}"])')
        lines.append(f"  class {ckey} {_status_class(status)};")
        if for_html:
            lines.append(f'  click {ckey} call toggleCluster("{status}")')
    return lines


def render_mermaid(graph: Graph) -> str:
    """Render the decomposition forest (the interrelated goals) as fenced Mermaid."""
    return "\n".join(["```mermaid", *_mermaid_body(graph, for_html=False), "```"])


def _cell(value: str | None) -> str:
    """Escape a free-text value (e.g. a git author name) for a table cell."""
    return value.replace("|", "\\|") if value else "—"


def _provenance(node: Node) -> str:
    bits = [_cell(node.solver)]
    if node.model:
        bits.append(f"`{node.model}`")
    return " · ".join(bits)


def render_markdown(graph: Graph) -> str:
    counts: dict[str, int] = {}
    for node in graph.nodes:
        counts[node.status] = counts.get(node.status, 0) + 1
    summary = " · ".join(
        f"{counts[s]} {s}" for s in sorted(counts, key=lambda s: _ORDER.get(s, 9))
    )
    n_families = len({edge.parent for edge in graph.edges})
    attributed = sum(1 for n in graph.nodes if n.status == "proved" and n.agent)
    n_proved = counts.get("proved", 0)

    lines = [
        "# Proof graph",
        "",
        "<!-- GENERATED by `python3 -m tools.visualiser --write`. Do not edit by hand. -->",
        "",
        "A visualiser for the swarm's proof graph (issue #371): every prove-goal, its "
        "status, the decomposition lineage that stacks sub-goals into their parents, and "
        "who solved each one. Click any node in the diagram to open its Lean statement.",
        "",
        "> An **interactive** version — pan/zoom, click-to-detail panel, filterable table — "
        f"is generated alongside this file at [`docs/{HTML_NAME}`]({HTML_NAME}) "
        "(open it locally or via GitHub Pages; the browser renders it, GitHub shows the source).",
        "",
        f"**{len(graph.nodes)} goals — {summary}.** "
        f"{n_families} decomposition {'family' if n_families == 1 else 'families'} shown below; "
        "standalone goals (no lineage) are folded into one summary cluster per "
        "status — the interactive page expands a cluster into its goals on click, "
        "and every goal is listed individually in the table.",
        "",
        f"Solving agent, PR and the GitHub user who merged it are resolved from the "
        f"`prove(…)` merge commits ({attributed} of {n_proved} proved goals carry a "
        "per-goal prove-PR; the rest predate that convention and are left blank). The "
        "solver shows the recorded AISP login where present, otherwise the merging "
        "GitHub user; the model comes from recorded provenance only — never guessed "
        "(ADR-023).",
        "",
        "## Dependency lineage",
        "",
        "Edges run **parent → sub-goal**: a parent is discharged once its sub-goals are "
        "proved (the keystone pattern behind big targets — see ADR-031 / issue #365).",
        "",
        render_mermaid(graph),
        "",
        "Legend: "
        + " · ".join(
            f"{status} {STATUS_STYLE.get(status, _DEFAULT_STYLE)[1]}"
            for status in ("proved", "open", "blocked", "flagged", "translated")
        ),
        "",
        "## All goals",
        "",
        "| Goal | Status | Difficulty | Agent | Solver / model | PR | Proved |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for node in sorted(graph.nodes, key=lambda n: (_ORDER.get(n.status, 9), n.id)):
        link = f"[`{node.id}`]({BLOB_BASE}/goals/{node.id}.lean)"
        pr = f"[#{node.pr}]({PR_BASE}/{node.pr})" if node.pr else "—"
        lines.append(
            f"| {link} | {node.status} | {node.difficulty or '—'} "
            f"| {node.agent or '—'} | {_provenance(node)} | {pr} | {node.date or '—'} |"
        )
    lines.append("")
    return "\n".join(lines)


def render_json(graph: Graph) -> str:
    return json.dumps(graph_payload(graph), indent=2, ensure_ascii=False) + "\n"


def graph_payload(graph: Graph) -> dict:
    return {
        "source": "goals/, decompositions/, library/index/, proof-runs/, prove(…) commits",
        "nodes": [asdict(node) for node in graph.nodes],
        "edges": [asdict(edge) for edge in graph.edges],
        # Standalone goals grouped by status (legend order) — the hybrid layout's
        # cluster feed the interactive page expands on click.
        "unconnected": [
            {"status": status, "ids": [node.id for node in members]}
            for status, members in _unconnected_by_status(graph).items()
        ],
    }


def _html_escape(value: str | None) -> str:
    return (
        (value or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


_HTML_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Unsorry — proof graph</title>
<!-- GENERATED by `python3 -m tools.visualiser --write`. Do not edit by hand. -->
<!-- Shares the #270 leaderboard design language (ADR-038): Tailwind + Inter,
     brand palette, centred white card, summary chips, mobile-first responsive. -->
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          brand: {
            50: '#f0fdfa', 100: '#ccfbf1', blue: '#e0f2fe',
            text: '#334155', muted: '#64748b',
            gold: '#fbbf24', silver: '#94a3b8', bronze: '#b45309'
          }
        },
        fontFamily: {
          sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
        }
      }
    }
  }
</script>
<style>
  body { background-color:#fafbfc; -webkit-font-smoothing:antialiased; }
  /* Status badges/swatches reuse the diagram's status fills (ADR-038). */
  .swatch { display:inline-block; width:.7rem; height:.7rem; border:1px solid #94a3b8; vertical-align:middle; margin-right:.3rem; border-radius:3px; }
  .badge { display:inline-flex; align-items:center; padding:.1rem .6rem; border-radius:999px; font-size:.78rem; font-weight:600; border:1px solid #cbd5e1; color:#334155; }
  .badge.proved{background:#c6f6d5}.badge.open{background:#e2e8f0}.badge.blocked{background:#feebc8}.badge.flagged{background:#fed7d7}.badge.translated{background:#bee3f8}
  .state-panel { border:1px dashed #cbd5e1; border-radius:14px; padding:18px; color:#64748b; background:#f8fafc; font-size:.9rem; }
  /* Scrollable regions: diagram pane + the goals table. */
  #scroller { overflow:auto; max-height:62vh; }
  #diagram { transform-origin:0 0; padding:.5rem; }
  ::-webkit-scrollbar { width:6px; height:6px; }
  ::-webkit-scrollbar-track { background:transparent; }
  ::-webkit-scrollbar-thumb { background:#cbd5e1; border-radius:4px; }
  ::-webkit-scrollbar-thumb:hover { background:#94a3b8; }
  /* Goals table — clean slate styling shared with the leaderboard look. */
  table.goals { border-collapse:collapse; width:100%; }
  table.goals th, table.goals td { text-align:left; padding:.5rem .7rem; border-bottom:1px solid #e2e8f0; font-size:.875rem; white-space:nowrap; }
  table.goals th { position:sticky; top:0; background:#f8fafc; color:#64748b; font-weight:600; text-transform:uppercase; letter-spacing:.03em; font-size:.72rem; z-index:1; }
  table.goals th[data-col] { cursor:pointer; user-select:none; }
  table.goals th[data-col]:hover { color:#334155; }
  table.goals th .sort-ind { color:#94a3b8; font-size:.7rem; }
  table.goals tbody tr { cursor:pointer; }
  table.goals tbody tr:hover { background:#f0fdfa; }
  table.goals tbody tr.sel { background:#ccfbf1; }
  code { background:#f1f5f9; padding:0 .3rem; border-radius:4px; font-size:.85em; }
  a.lnk { color:#0369a1; text-decoration:none; } a.lnk:hover { text-decoration:underline; }
  aside dl { display:grid; grid-template-columns:auto 1fr; gap:.35rem .9rem; margin:.75rem 0 0; font-size:.9rem; }
  aside dt { color:#64748b; }
  aside dd { margin:0; color:#334155; }
</style>
</head>
<body class="font-sans text-brand-text p-4 md:p-8 flex justify-center items-start min-h-screen">
<main class="w-full max-w-6xl bg-white rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-100 overflow-hidden">

  <!-- Top navigation — shared across home / leaderboard / proof graph (issue #738). -->
  <nav class="flex items-center gap-1 px-6 md:px-10 py-3 text-sm font-medium border-b border-slate-100" aria-label="Primary">
    <a href="index.html" class="px-3 py-1.5 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800 transition-colors">Home</a>
    <a href="leaderboard.html" class="px-3 py-1.5 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800 transition-colors">Leaderboard</a>
    <a href="proofs-contributors-visualisation.html" aria-current="page" class="px-3 py-1.5 rounded-lg bg-slate-100 text-slate-800">Proof graph</a>
  </nav>

  <!-- Header — shared design language (ADR-038): wordmark, status chip, cross-link, stat chips. -->
  <header class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 px-6 md:px-10 py-6 md:py-8 border-b border-slate-100">
    <div class="flex flex-col">
      <h1 class="text-5xl md:text-7xl font-bold text-slate-200 tracking-tighter leading-none mb-2">Unsorry</h1>
      <div class="inline-flex items-center bg-slate-100 rounded-full px-4 py-1 text-xs font-semibold text-slate-600 uppercase tracking-wider w-max">
        Proof graph · __COUNT__ goals
      </div>
    </div>
    <div class="flex flex-wrap gap-2" id="stat-chips">
__STATCHIPS__
    </div>
  </header>

  <!-- Toolbar — wraps on narrow viewports. -->
  <div class="flex flex-wrap gap-2 items-center px-6 md:px-10 py-3 border-b border-slate-100 sticky top-0 bg-white/95 backdrop-blur z-10">
    <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider mr-1">Diagram</span>
    <button id="zout" class="px-3 py-1 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-sm">−</button>
    <button id="zreset" class="px-3 py-1 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-sm">reset</button>
    <button id="zin" class="px-3 py-1 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-sm">+</button>
    <span class="flex-1 min-w-[1rem]"></span>
    <input id="q" type="search" placeholder="filter goals / agent / solver…" autocomplete="off"
      class="px-3 py-1.5 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue w-full sm:w-auto">
    <select id="status" class="px-3 py-1.5 rounded-lg border border-slate-200 text-sm bg-white">
      <option value="">all statuses</option>
      <option value="proved">proved</option>
      <option value="open">open</option>
      <option value="blocked">blocked</option>
      <option value="flagged">flagged</option>
      <option value="translated">translated</option>
    </select>
  </div>

  <!-- Diagram + detail panel: stacks on mobile, side-by-side from lg. -->
  <div class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_320px]">
    <div id="scroller" class="border-b lg:border-b-0 lg:border-r border-slate-100 bg-white">
      <div id="diagram"><pre class="mermaid">
__MERMAID__
</pre></div>
    </div>
    <aside id="panel" class="p-6">
      <div class="state-panel">Select a node or a table row to see who solved it, the model, the PR, and a link to its Lean statement.</div>
    </aside>
  </div>

  <!-- Goals table — scrolls horizontally within the card on narrow screens. -->
  <section class="px-6 md:px-10 py-6 md:py-8">
    <h2 class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">All goals</h2>
    <div class="overflow-x-auto rounded-xl border border-slate-100">
      <table class="goals">
        <thead><tr>
          <th data-col="0">Goal<span class="sort-ind"></span></th>
          <th data-col="1">Status<span class="sort-ind"></span></th>
          <th data-col="2">Diff<span class="sort-ind"></span></th>
          <th data-col="3">Agent<span class="sort-ind"></span></th>
          <th data-col="4">Solver / model<span class="sort-ind"></span></th>
          <th data-col="5">PR<span class="sort-ind"></span></th>
          <th data-col="6">Proved<span class="sort-ind"></span></th>
        </tr></thead>
        <tbody id="rows">
__ROWS__
        </tbody>
      </table>
    </div>
  </section>

</main>
<script type="application/json" id="graph-data">__DATA__</script>
<script type="module">
  import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
  const data = JSON.parse(document.getElementById("graph-data").textContent);
  const byId = {}; data.nodes.forEach(n => { byId[n.id] = n; });
  const BLOB = "__BLOB__/goals", PR = "__PRBASE__";
  const esc = s => (s==null?"":String(s)).replace(/[&<>]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]));

  window.showDetail = function (id) {
    const n = byId[id]; if (!n) return;
    const pr = n.pr ? `<a class="lnk" href="${PR}/${n.pr}">#${n.pr}</a>` : "—";
    const model = n.model ? `<code>${esc(n.model)}</code>` : "—";
    document.getElementById("panel").innerHTML =
      `<h2 class="text-lg font-semibold text-slate-800 break-all mb-2"><a class="lnk" href="${BLOB}/${id}.lean"><code>${esc(id)}</code></a></h2>` +
      `<span class="badge ${esc(n.status)}">${esc(n.status)}</span>` +
      `<dl><dt>Difficulty</dt><dd>${n.difficulty || "—"}</dd>` +
      `<dt>Agent</dt><dd>${esc(n.agent) || "—"}</dd>` +
      `<dt>Solver</dt><dd>${esc(n.solver) || "—"}</dd>` +
      `<dt>Model</dt><dd>${model}</dd>` +
      `<dt>PR</dt><dd>${pr}</dd>` +
      `<dt>Proved</dt><dd>${esc(n.date) || "—"}</dd></dl>`;
    document.querySelectorAll("tr.sel").forEach(r => r.classList.remove("sel"));
    const row = document.querySelector(`tr[data-id="${id}"]`);
    if (row) { row.classList.add("sel"); row.scrollIntoView({ block:"nearest" }); }
  };

  const q = document.getElementById("q"), st = document.getElementById("status");
  function applyFilter() {
    const term = q.value.toLowerCase(), s = st.value;
    document.querySelectorAll("#rows tr").forEach(r => {
      const hay = [r.dataset.id, r.dataset.agent, r.dataset.solver].join(" ").toLowerCase();
      const ok = hay.includes(term) && (!s || r.dataset.status === s);
      r.style.display = ok ? "" : "none";
    });
  }
  q.addEventListener("input", applyFilter); st.addEventListener("change", applyFilter);
  document.querySelectorAll("#rows tr").forEach(r => r.addEventListener("click", () => showDetail(r.dataset.id)));

  // Click a column heading to sort the goals table (first click A→Z, click again Z→A) (#738).
  (function () {
    const tbody = document.getElementById("rows");
    const heads = document.querySelectorAll("table.goals th[data-col]");
    let sortedCol = -1, dir = 1;
    const cell = (tr, c) => (tr.children[c] ? tr.children[c].textContent : "").trim();
    heads.forEach(th => th.addEventListener("click", () => {
      const col = Number(th.dataset.col);
      dir = (sortedCol === col) ? -dir : 1;
      sortedCol = col;
      const rows = Array.from(tbody.querySelectorAll("tr"));
      rows.sort((a, b) => {
        const av = cell(a, col), bv = cell(b, col);
        const an = parseFloat(av), bn = parseFloat(bv);
        const cmp = (!isNaN(an) && !isNaN(bn) && av !== "" && bv !== "")
          ? an - bn : av.toLowerCase().localeCompare(bv.toLowerCase());
        return cmp * dir;
      });
      rows.forEach(r => tbody.appendChild(r));
      heads.forEach(h => { const s = h.querySelector(".sort-ind"); if (s) s.textContent = ""; });
      const ind = th.querySelector(".sort-ind"); if (ind) ind.textContent = dir === 1 ? " ▲" : " ▼";
    }));
  })();

  let scale = 1; const diagram = document.getElementById("diagram");
  const zoom = s => { scale = Math.max(0.3, Math.min(3, s)); diagram.style.transform = `scale(${scale})`; };
  document.getElementById("zin").onclick = () => zoom(scale + 0.15);
  document.getElementById("zout").onclick = () => zoom(scale - 0.15);
  document.getElementById("zreset").onclick = () => zoom(1);

  mermaid.initialize({ startOnLoad: true, securityLevel: "loose",
    themeVariables: { fontFamily: "Inter, system-ui, sans-serif" },
    flowchart: { useMaxWidth: false } });

  // ── Hybrid layout: decomposition forest + per-status clusters of standalone
  // goals. The server-rendered <pre> paints the initial collapsed diagram (and is
  // the no-JS fallback); clicking a cluster rebuilds the Mermaid source from the
  // embedded model — expanding that status into its individual goals — and
  // re-renders. Mirrors `_mermaid_body` so collapsed JS output matches the server.
  const STATUS_FILLS = { proved: "#c6f6d5", open: "#e2e8f0", blocked: "#feebc8",
    flagged: "#fed7d7", translated: "#bee3f8", unknown: "#edf2f7" };
  const nodeKey = id => "g_" + String(id).replace(/[^0-9a-z]/g, "_");
  const clusterKey = s => "cluster_" + String(s).replace(/[^0-9a-z]/g, "_");
  const statusClass = s => STATUS_FILLS[s] ? s : "unknown";
  const expanded = new Set();

  function buildMermaidSource(open) {
    const inForest = new Set();
    data.edges.forEach(e => { inForest.add(e.parent); inForest.add(e.child); });
    const lines = ["flowchart LR"];
    Object.keys(STATUS_FILLS).forEach(s =>
      lines.push(`  classDef ${s} fill:${STATUS_FILLS[s]},stroke:#4a5568,color:#1a202c;`));
    data.nodes.forEach(n => {
      if (!inForest.has(n.id)) return;
      const k = nodeKey(n.id);
      lines.push(`  ${k}["${n.id}"]`, `  class ${k} ${statusClass(n.status)};`,
        `  click ${k} call showDetail("${n.id}")`);
    });
    data.edges.slice()
      .sort((a, b) => (a.parent + "→" + a.child).localeCompare(b.parent + "→" + b.child))
      .forEach(e => lines.push(`  ${nodeKey(e.parent)} --> ${nodeKey(e.child)}`));
    (data.unconnected || []).forEach(({ status, ids }) => {
      const ck = clusterKey(status), n = ids.length, cls = statusClass(status);
      if (open.has(status)) {
        lines.push(`  subgraph sg_${ck}["${status} · ${n}"]`,
          `    ${ck}(["▾ ${status} · ${n}"])`,
          `    class ${ck} ${cls};`, `    click ${ck} call toggleCluster("${status}")`);
        ids.forEach(id => {
          const k = nodeKey(id);
          lines.push(`    ${k}["${id}"]`, `    class ${k} ${cls};`,
            `    click ${k} call showDetail("${id}")`);
        });
        lines.push("  end");
      } else {
        lines.push(`  ${ck}(["▸ ${status} · ${n}"])`,
          `  class ${ck} ${cls};`, `  click ${ck} call toggleCluster("${status}")`);
      }
    });
    return lines.join("\\n");
  }

  let renderSeq = 0;
  async function renderDiagram() {
    try {
      const { svg, bindFunctions } =
        await mermaid.render("pg-diagram-" + (++renderSeq), buildMermaidSource(expanded));
      diagram.innerHTML = svg;
      if (bindFunctions) bindFunctions(diagram);
    } catch (err) { console.error("diagram render failed", err); }
  }

  window.toggleCluster = function (status) {
    if (expanded.has(status)) expanded.delete(status); else expanded.add(status);
    renderDiagram();
  };
</script>
</body>
</html>
"""


def render_html(graph: Graph) -> str:
    """A standalone, interactive page (issue #371, Phase 2).

    Embeds the graph model and the Mermaid forest; mermaid.js (CDN) renders it,
    clicking a node (or table row) opens a detail panel, and the table filters by
    text/status. Self-contained except for the mermaid ESM module.
    """
    counts: dict[str, int] = {}
    for node in graph.nodes:
        counts[node.status] = counts.get(node.status, 0) + 1
    mermaid_def = "\n".join(_mermaid_body(graph, for_html=True))

    # Header summary stat chips, one per present status (proved-last order), each
    # carrying the diagram's status swatch so the header and the forest read alike.
    chips: list[str] = []
    for status in sorted(counts, key=lambda s: _ORDER.get(s, 9)):
        fill = STATUS_STYLE.get(status, _DEFAULT_STYLE)[1]
        chips.append(
            '<span class="inline-flex items-center bg-white border border-slate-200 '
            'text-slate-600 px-3 py-1.5 rounded-xl text-sm font-medium">'
            f'<i class="swatch" style="background:{fill}"></i>'
            f'{counts[status]} {status}</span>'
        )

    rows: list[str] = []
    for node in sorted(graph.nodes, key=lambda n: (_ORDER.get(n.status, 9), n.id)):
        model = f"<code>{_html_escape(node.model)}</code>" if node.model else "—"
        pr = (
            f'<a class="lnk" href="{PR_BASE}/{node.pr}">#{node.pr}</a>' if node.pr else "—"
        )
        rows.append(
            f'<tr data-id="{_html_escape(node.id)}" data-status="{node.status}" '
            f'data-agent="{_html_escape(node.agent)}" data-solver="{_html_escape(node.solver)}">'
            f'<td><a class="lnk" href="{BLOB_BASE}/goals/{node.id}.lean"><code>{_html_escape(node.id)}</code></a></td>'
            f'<td><span class="badge {node.status}">{node.status}</span></td>'
            f"<td>{node.difficulty or '—'}</td>"
            f"<td>{_html_escape(node.agent) or '—'}</td>"
            f"<td>{_html_escape(node.solver) or '—'} {('· ' + model) if node.model else ''}</td>"
            f"<td>{pr}</td>"
            f"<td>{_html_escape(node.date) or '—'}</td></tr>"
        )

    return (
        _HTML_TEMPLATE.replace("__COUNT__", str(len(graph.nodes)))
        .replace("__STATCHIPS__", "\n".join(chips))
        .replace("__MERMAID__", mermaid_def)
        .replace("__ROWS__", "\n".join(rows))
        .replace("__DATA__", json.dumps(graph_payload(graph), ensure_ascii=False))
        .replace("__BLOB__", BLOB_BASE)
        .replace("__PRBASE__", PR_BASE)
    )


def render_svg(graph: Graph) -> str:
    """A README preview card for the proof graph (ADR-038, the leaderboard's
    two-surface pattern).

    A self-contained SVG — white rounded card, Inter title, a per-status bar
    breakdown using the diagram's status fills — that mirrors ``docs/leaderboard.svg``
    so the README reads as one product. Deterministic: it is a pure function of the
    goals' statuses (no git provenance), so it never drifts on a shallow checkout.
    """
    counts: dict[str, int] = {}
    for node in graph.nodes:
        counts[node.status] = counts.get(node.status, 0) + 1
    # Ranked bars (count desc), legend order as the tie-break.
    statuses = sorted(counts, key=lambda s: (-counts[s], _ORDER.get(s, 9)))
    total = len(graph.nodes)
    proved = counts.get("proved", 0)
    families = len({edge.parent for edge in graph.edges})
    max_count = max(list(counts.values()) + [1])

    width = 900
    top = 110
    row_h = 52
    rows = max(1, len(statuses))
    height = top + rows * row_h + 24
    font = "Inter, system-ui, sans-serif"
    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">Unsorry proof graph</title>',
        '<desc id="desc">Unsorry proof graph: goals by status, with the '
        "decomposition-lineage family count.</desc>",
        f'<rect width="{width}" height="100%" rx="18" fill="#ffffff"/>',
        f'<rect x="0.5" y="0.5" width="{width - 1}" height="{height - 1}" rx="18" '
        'fill="none" stroke="#e2e8f0"/>',
        f'<text x="32" y="44" font-family="{font}" font-size="28" font-weight="700" '
        'fill="#334155">Unsorry Proof Graph</text>',
        f'<text x="32" y="72" font-family="{font}" font-size="13" fill="#64748b">'
        f"{total} goals · {proved} proved · {families} decomposition "
        f"{'family' if families == 1 else 'families'}</text>",
    ]
    if not statuses:
        lines.append(
            f'<text x="32" y="{top + 30}" font-family="{font}" font-size="16" '
            'fill="#64748b">No goals yet.</text>'
        )
    for index, status in enumerate(statuses):
        count = counts[status]
        fill = STATUS_STYLE.get(status, _DEFAULT_STYLE)[1]
        y = top + index * row_h
        bar_w = max(6, int(420 * count / max_count))
        pct = round(100 * count / total) if total else 0
        lines.extend([
            f'<rect x="32" y="{y + 13}" width="15" height="15" rx="3" fill="{fill}" '
            'stroke="#94a3b8"/>',
            f'<text x="58" y="{y + 26}" font-family="{font}" font-size="16" '
            f'font-weight="650" fill="#334155">{_html_escape(status)}</text>',
            f'<text x="58" y="{y + 44}" font-family="{font}" font-size="12" '
            f'fill="#64748b">{count} of {total} goals · {pct}%</text>',
            f'<rect x="300" y="{y + 15}" width="420" height="24" rx="12" fill="#f1f5f9"/>',
            f'<rect x="300" y="{y + 15}" width="{bar_w}" height="24" rx="12" fill="{fill}"/>',
            f'<text x="740" y="{y + 33}" font-family="{font}" font-size="14" '
            f'font-weight="700" fill="#334155">{count}</text>',
        ])
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    flags = ("--check", "--write", "--json", "--html", "--svg")
    modes = [flag for flag in flags if flag in argv]
    if len(modes) > 1:
        print(f"{', '.join(flags)} are mutually exclusive", file=sys.stderr)
        return 2
    mode = modes[0] if modes else None
    rest = [arg for arg in argv if arg not in flags]
    root = Path(rest[0]) if rest else Path(".")

    graph = build_graph(root)
    if mode == "--json":
        sys.stdout.write(render_json(graph))
        return 0
    if mode == "--html":
        sys.stdout.write(render_html(graph))
        return 0
    if mode == "--svg":
        sys.stdout.write(render_svg(graph))
        return 0

    # The markdown view, the interactive HTML, and the README SVG preview are
    # written and drift-checked together — three views of the same graph.
    artifacts = [
        (root / "docs" / MD_NAME, render_markdown(graph) + "\n"),
        (root / "docs" / HTML_NAME, render_html(graph)),
        (root / "docs" / SVG_NAME, render_svg(graph)),
    ]
    if mode == "--write":
        for target, content in artifacts:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        return 0
    if mode == "--check":
        stale = [
            target
            for target, content in artifacts
            if (target.read_text(encoding="utf-8") if target.exists() else "") != content
        ]
        if stale:
            names = ", ".join(str(t) for t in stale)
            print(
                f"{names} stale; regenerate with `python3 -m tools.visualiser --write`",
                file=sys.stderr,
            )
            return 1
        return 0
    sys.stdout.write(render_markdown(graph) + "\n")
    return 0
