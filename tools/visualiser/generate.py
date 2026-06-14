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
only impurity and degrades to empty outside a checkout; because ``docs/graph.md``
then tracks the proof-commit history it must be regenerated when proofs merge
(as the targets board is) before ``--check`` is gated in CI.

Usage::

    python3 -m tools.visualiser [<repo-root>]            # markdown to stdout
    python3 -m tools.visualiser --json [<repo-root>]     # graph model as JSON
    python3 -m tools.visualiser --html [<repo-root>]     # interactive HTML to stdout
    python3 -m tools.visualiser --write [<repo-root>]    # write docs/graph.{md,html}
    python3 -m tools.visualiser --check [<repo-root>]    # CI drift check (both)
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
        "is generated alongside this file at [`docs/graph.html`](graph.html) "
        "(open it locally or via GitHub Pages; the browser renders it, GitHub shows the source).",
        "",
        f"**{len(graph.nodes)} goals — {summary}.** "
        f"{n_families} decomposition {'family' if n_families == 1 else 'families'} shown below; "
        "standalone goals are listed in the table.",
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
<title>unsorry — proof graph</title>
<!-- GENERATED by `python3 -m tools.visualiser --write`. Do not edit by hand. -->
<style>
  :root { --bg:#f7fafc; --fg:#1a202c; --muted:#718096; --line:#e2e8f0; --accent:#2b6cb0; }
  * { box-sizing:border-box; }
  body { margin:0; font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; color:var(--fg); background:var(--bg); }
  header { padding:1rem 1.25rem; border-bottom:1px solid var(--line); background:#fff; }
  header h1 { margin:0 0 .25rem; font-size:1.3rem; }
  header p { margin:.15rem 0; color:var(--muted); }
  .legend span { display:inline-block; margin-right:.6rem; font-size:.85rem; }
  .swatch { display:inline-block; width:.8rem; height:.8rem; border:1px solid #4a5568; vertical-align:middle; margin-right:.25rem; border-radius:2px; }
  .toolbar { display:flex; flex-wrap:wrap; gap:.5rem; align-items:center; padding:.6rem 1.25rem; border-bottom:1px solid var(--line); background:#fff; position:sticky; top:0; z-index:5; }
  .toolbar input, .toolbar select { padding:.35rem .5rem; border:1px solid var(--line); border-radius:6px; font:inherit; }
  .toolbar button { padding:.35rem .6rem; border:1px solid var(--line); background:#fff; border-radius:6px; cursor:pointer; font:inherit; }
  .toolbar button:hover { background:var(--line); }
  main { display:grid; grid-template-columns:1fr 320px; gap:0; align-items:stretch; }
  #scroller { overflow:auto; max-height:62vh; border-right:1px solid var(--line); background:#fff; }
  #diagram { transform-origin:0 0; padding:1rem; }
  aside { padding:1rem 1.25rem; background:#fff; }
  aside h2 { margin:.2rem 0 .5rem; font-size:1.05rem; word-break:break-all; }
  aside dl { display:grid; grid-template-columns:auto 1fr; gap:.2rem .75rem; margin:.5rem 0 0; }
  aside dt { color:var(--muted); }
  aside dd { margin:0; }
  .badge { display:inline-block; padding:.05rem .5rem; border-radius:999px; font-size:.8rem; border:1px solid #4a5568; }
  .badge.proved{background:#c6f6d5}.badge.open{background:#e2e8f0}.badge.blocked{background:#feebc8}.badge.flagged{background:#fed7d7}.badge.translated{background:#bee3f8}
  table { border-collapse:collapse; width:100%; background:#fff; }
  th, td { text-align:left; padding:.4rem .6rem; border-bottom:1px solid var(--line); font-size:.9rem; }
  th { position:sticky; top:0; background:#edf2f7; cursor:default; }
  tbody tr { cursor:pointer; }
  tbody tr:hover { background:#f0f5ff; }
  tbody tr.sel { background:#dbeafe; }
  code { background:#edf2f7; padding:0 .25rem; border-radius:4px; }
  a { color:var(--accent); text-decoration:none; } a:hover { text-decoration:underline; }
  .wrap { padding:0 1.25rem 2rem; }
  h2.section { margin:1.2rem 0 .5rem; }
</style>
</head>
<body>
<header>
  <h1>unsorry — proof graph</h1>
  <p>__SUMMARY__. Click a node or row for details. Source: the AISP records + the <code>prove(…)</code> commits (issue #371).</p>
  <p class="legend">
    <span><i class="swatch" style="background:#c6f6d5"></i>proved</span>
    <span><i class="swatch" style="background:#e2e8f0"></i>open</span>
    <span><i class="swatch" style="background:#feebc8"></i>blocked</span>
    <span><i class="swatch" style="background:#fed7d7"></i>flagged</span>
    <span><i class="swatch" style="background:#bee3f8"></i>translated</span>
  </p>
</header>
<div class="toolbar">
  <strong>Diagram:</strong>
  <button id="zout">−</button><button id="zreset">reset</button><button id="zin">+</button>
  <span style="flex:1"></span>
  <input id="q" type="search" placeholder="filter goals / agent / solver…" autocomplete="off">
  <select id="status">
    <option value="">all statuses</option>
    <option value="proved">proved</option>
    <option value="open">open</option>
    <option value="blocked">blocked</option>
    <option value="flagged">flagged</option>
    <option value="translated">translated</option>
  </select>
</div>
<main>
  <div id="scroller"><div id="diagram"><pre class="mermaid">
__MERMAID__
</pre></div></div>
  <aside id="panel"><p style="color:#718096">Select a node or a table row to see who solved it, the model, the PR, and a link to its Lean statement.</p></aside>
</main>
<div class="wrap">
  <h2 class="section">All goals</h2>
  <table>
    <thead><tr><th>Goal</th><th>Status</th><th>Diff</th><th>Agent</th><th>Solver / model</th><th>PR</th><th>Proved</th></tr></thead>
    <tbody id="rows">
__ROWS__
    </tbody>
  </table>
</div>
<script type="application/json" id="graph-data">__DATA__</script>
<script type="module">
  import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
  const data = JSON.parse(document.getElementById("graph-data").textContent);
  const byId = {}; data.nodes.forEach(n => { byId[n.id] = n; });
  const BLOB = "__BLOB__/goals", PR = "__PRBASE__";
  const esc = s => (s==null?"":String(s)).replace(/[&<>]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]));

  window.showDetail = function (id) {
    const n = byId[id]; if (!n) return;
    const pr = n.pr ? `<a href="${PR}/${n.pr}">#${n.pr}</a>` : "—";
    const model = n.model ? `<code>${esc(n.model)}</code>` : "—";
    document.getElementById("panel").innerHTML =
      `<h2><a href="${BLOB}/${id}.lean"><code>${esc(id)}</code></a></h2>` +
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

  let scale = 1; const diagram = document.getElementById("diagram");
  const zoom = s => { scale = Math.max(0.3, Math.min(3, s)); diagram.style.transform = `scale(${scale})`; };
  document.getElementById("zin").onclick = () => zoom(scale + 0.15);
  document.getElementById("zout").onclick = () => zoom(scale - 0.15);
  document.getElementById("zreset").onclick = () => zoom(1);

  mermaid.initialize({ startOnLoad: true, securityLevel: "loose", flowchart: { useMaxWidth: false } });
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
    summary = " · ".join(
        f"{counts[s]} {s}" for s in sorted(counts, key=lambda s: _ORDER.get(s, 9))
    )
    mermaid_def = "\n".join(_mermaid_body(graph, for_html=True))

    rows: list[str] = []
    for node in sorted(graph.nodes, key=lambda n: (_ORDER.get(n.status, 9), n.id)):
        model = f"<code>{_html_escape(node.model)}</code>" if node.model else "—"
        pr = (
            f'<a href="{PR_BASE}/{node.pr}">#{node.pr}</a>' if node.pr else "—"
        )
        rows.append(
            f'<tr data-id="{_html_escape(node.id)}" data-status="{node.status}" '
            f'data-agent="{_html_escape(node.agent)}" data-solver="{_html_escape(node.solver)}">'
            f'<td><a href="{BLOB_BASE}/goals/{node.id}.lean"><code>{_html_escape(node.id)}</code></a></td>'
            f'<td><span class="badge {node.status}">{node.status}</span></td>'
            f"<td>{node.difficulty or '—'}</td>"
            f"<td>{_html_escape(node.agent) or '—'}</td>"
            f"<td>{_html_escape(node.solver) or '—'} {('· ' + model) if node.model else ''}</td>"
            f"<td>{pr}</td>"
            f"<td>{_html_escape(node.date) or '—'}</td></tr>"
        )

    return (
        _HTML_TEMPLATE.replace("__SUMMARY__", f"{len(graph.nodes)} goals — {summary}")
        .replace("__MERMAID__", mermaid_def)
        .replace("__ROWS__", "\n".join(rows))
        .replace("__DATA__", json.dumps(graph_payload(graph), ensure_ascii=False))
        .replace("__BLOB__", BLOB_BASE)
        .replace("__PRBASE__", PR_BASE)
    )


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    flags = ("--check", "--write", "--json", "--html")
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

    # `docs/graph.md` (markdown) and `docs/graph.html` (interactive) are written
    # and drift-checked together — two renderings of the same graph.
    artifacts = [
        (root / "docs" / "graph.md", render_markdown(graph) + "\n"),
        (root / "docs" / "graph.html", render_html(graph)),
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
