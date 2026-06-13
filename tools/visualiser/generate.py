"""Generate the proof-graph visualiser (issue #371, ADR-032).

A V1 visualiser for the swarm's proof graph: every prove-goal as a node coloured
by status, the decomposition lineage as edges (parent → sub-goal), and a complete
provenance table (who solved each goal, when, with which model). The diagram is a
GitHub-native Mermaid ``flowchart`` so it renders in the browser with zero
JavaScript; the interactive HTML surface (issue #371, Phase 2) consumes the same
``--json`` model.

The generator is **pure over the in-repo AISP coordination records** — it reads
``goals/``, ``decompositions/``, ``library/index/`` and ``proof-runs/`` and never
shells out to git — so ``--check`` is a deterministic CI drift guard, mirroring
``tools.sourcing.targets_board`` and ``tools.leaderboard``.

Usage::

    python3 -m tools.visualiser [<repo-root>]            # markdown to stdout
    python3 -m tools.visualiser --json [<repo-root>]     # graph model as JSON
    python3 -m tools.visualiser --write [<repo-root>]    # write docs/graph.md
    python3 -m tools.visualiser --check [<repo-root>]    # CI drift check
"""
from __future__ import annotations

import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

from tools.gate_b.records import parse_record
from tools.leaderboard.generate import goals as _goals
from tools.leaderboard.generate import proofs as _proofs

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

_SUB_ID_RE = re.compile(r"id≜([a-z0-9][a-z0-9-]*)")


@dataclass(frozen=True)
class Node:
    id: str
    status: str
    difficulty: int
    solver: str | None
    date: str | None
    model: str | None


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


def build_graph(root: Path) -> Graph:
    """Assemble the proof graph from the AISP coordination records."""
    goal_records = _goals(root)
    by_goal = {proof.goal: proof for proof in _proofs(root, goal_records)}
    nodes = tuple(
        Node(
            id=goal.id,
            status=goal.status,
            difficulty=goal.difficulty,
            solver=(p.solver if (p := by_goal.get(goal.id)) else None),
            date=(p.date or None if (p := by_goal.get(goal.id)) else None),
            model=(p.model if (p := by_goal.get(goal.id)) else None),
        )
        for goal in sorted(goal_records, key=lambda g: g.id)
    )
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


def render_mermaid(graph: Graph) -> str:
    """Render the decomposition forest (the interrelated goals) as Mermaid."""
    in_forest = {edge.parent for edge in graph.edges} | {
        edge.child for edge in graph.edges
    }
    lines = ["```mermaid", "flowchart LR"]
    # Class definitions (status colours).
    for status, (cls, fill) in STATUS_STYLE.items():
        lines.append(f"  classDef {cls} fill:{fill},stroke:#4a5568,color:#1a202c;")
    lines.append(f"  classDef {_DEFAULT_STYLE[0]} fill:{_DEFAULT_STYLE[1]},stroke:#4a5568,color:#1a202c;")
    # Nodes that participate in a decomposition, with click-through links.
    for node in graph.nodes:
        if node.id not in in_forest:
            continue
        key = _node_key(node.id)
        lines.append(f'  {key}["{node.id}"]')
        lines.append(f"  class {key} {_status_class(node.status)};")
        lines.append(
            f'  click {key} "{BLOB_BASE}/goals/{node.id}.lean" "{node.id} — {node.status}"'
        )
    # Edges (parent → sub-goal).
    for edge in sorted(graph.edges, key=lambda e: (e.parent, e.child)):
        lines.append(f"  {_node_key(edge.parent)} --> {_node_key(edge.child)}")
    lines.append("```")
    return "\n".join(lines)


def _provenance(node: Node) -> str:
    bits = [node.solver or "—"]
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

    lines = [
        "# Proof graph",
        "",
        "<!-- GENERATED by `python3 -m tools.visualiser --write`. Do not edit by hand. -->",
        "",
        "A visualiser for the swarm's proof graph (issue #371): every prove-goal, its "
        "status, the decomposition lineage that stacks sub-goals into their parents, and "
        "who solved each one. Click any node in the diagram to open its Lean statement.",
        "",
        f"**{len(graph.nodes)} goals — {summary}.** "
        f"{n_families} decomposition {'family' if n_families == 1 else 'families'} shown below; "
        "standalone goals are listed in the table.",
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
        "| Goal | Status | Difficulty | Solver / model | Proved |",
        "| --- | --- | --- | --- | --- |",
    ]
    for node in sorted(graph.nodes, key=lambda n: (_ORDER.get(n.status, 9), n.id)):
        link = f"[`{node.id}`]({BLOB_BASE}/goals/{node.id}.lean)"
        lines.append(
            f"| {link} | {node.status} | {node.difficulty or '—'} "
            f"| {_provenance(node)} | {node.date or '—'} |"
        )
    lines.append("")
    return "\n".join(lines)


def render_json(graph: Graph) -> str:
    payload = {
        "source": "goals/, decompositions/, library/index/, proof-runs/",
        "nodes": [asdict(node) for node in graph.nodes],
        "edges": [asdict(edge) for edge in graph.edges],
    }
    return json.dumps(payload, indent=2, ensure_ascii=False) + "\n"


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    modes = [flag for flag in ("--check", "--write", "--json") if flag in argv]
    if len(modes) > 1:
        print("--check, --write, and --json are mutually exclusive", file=sys.stderr)
        return 2
    mode = modes[0] if modes else None
    rest = [arg for arg in argv if arg not in ("--check", "--write", "--json")]
    root = Path(rest[0]) if rest else Path(".")

    graph = build_graph(root)
    if mode == "--json":
        sys.stdout.write(render_json(graph))
        return 0

    markdown = render_markdown(graph)
    target = root / "docs" / "graph.md"
    if mode == "--write":
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(markdown + "\n", encoding="utf-8")
        return 0
    if mode == "--check":
        current = target.read_text(encoding="utf-8") if target.exists() else ""
        if current != markdown + "\n":
            print(
                f"{target} is stale; regenerate with "
                "`python3 -m tools.visualiser --write`",
                file=sys.stderr,
            )
            return 1
        return 0
    sys.stdout.write(markdown + "\n")
    return 0
