"""Proof-graph visualiser tests (ADR-032). Fixture AISP tree — no network."""
from __future__ import annotations

from pathlib import Path

import re

from tools.visualiser.generate import (
    build_graph,
    main,
    parse_prove_log,
    render_html,
    render_json,
    render_markdown,
    render_mermaid,
    render_svg,
)


def _goal(root: Path, gid: str, status: str, difficulty: int = 1) -> None:
    (root / "goals").mkdir(exist_ok=True)
    (root / "goals" / f"{gid}.aisp").write_text(
        f"𝔸5.1.goal.{gid}@2026-06-13\n"
        "γ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{id≜{gid}; phase≜prove; status≜{status}; difficulty≜{difficulty}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )
    (root / "goals" / f"{gid}.lean").write_text("theorem t : True := trivial\n", "utf-8")


def _index(root: Path, gid: str, *, solver: str, model: str, date: str = "2026-06-13") -> None:
    (root / "library" / "index").mkdir(parents=True, exist_ok=True)
    sha = "0" * 64
    (root / "library" / "index" / f"{gid}.aisp").write_text(
        f"𝔸5.1.lemma.{gid}@{date}\n"
        "γ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{gid}; name≜{gid.replace('-', '_')}}}\n"
        f"⟦Π:Provenance⟧{{solver≜{solver}; provider≜claude; model≜{model}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def _decomp(root: Path, parent: str, subs: list[str], agent: str = "agent-x") -> None:
    (root / "decompositions").mkdir(exist_ok=True)
    sub_lines = "\n".join(
        f"  sub{i}≜⟨id≜{sub},sha≜{'a' * 64}⟩" for i, sub in enumerate(subs, 1)
    )
    (root / "decompositions" / f"{parent}.{agent}.aisp").write_text(
        f"𝔸5.1.decomp.{parent}.{agent}@2026-06-13\n"
        "γ≔unsorry.decomposition\n"
        f"⟦Ω:Decomp⟧{{parent≜{parent}; agent≜{agent}}}\n"
        f"⟦Σ:Subs⟧{{\n{sub_lines}\n}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def _repo(tmp_path: Path) -> Path:
    _goal(tmp_path, "parent", "open", difficulty=3)
    _goal(tmp_path, "parent-s1", "proved")
    _goal(tmp_path, "parent-s2", "proved")
    _goal(tmp_path, "standalone", "proved")
    _index(tmp_path, "parent-s1", solver="alice", model="opus")
    _index(tmp_path, "standalone", solver="bob", model="sonnet")
    _decomp(tmp_path, "parent", ["parent-s1", "parent-s2"])
    return tmp_path


def test_build_graph_nodes_and_provenance(tmp_path):
    graph = build_graph(_repo(tmp_path))
    by_id = {n.id: n for n in graph.nodes}
    assert set(by_id) == {"parent", "parent-s1", "parent-s2", "standalone"}
    assert by_id["parent"].status == "open" and by_id["parent"].difficulty == 3
    assert by_id["parent-s1"].solver == "alice" and by_id["parent-s1"].model == "opus"
    assert by_id["parent-s1"].date == "2026-06-13"
    # No index record → no provenance, not a crash.
    assert by_id["parent"].solver is None


def test_decomposition_edges(tmp_path):
    graph = build_graph(_repo(tmp_path))
    assert set((e.parent, e.child) for e in graph.edges) == {
        ("parent", "parent-s1"),
        ("parent", "parent-s2"),
    }
    assert all(e.agent == "agent-x" for e in graph.edges)


def test_stale_edges_dropped(tmp_path):
    _repo(tmp_path)
    _decomp(tmp_path, "ghost-parent", ["ghost-sub"], agent="zz")  # no such goals
    graph = build_graph(tmp_path)
    assert all(e.parent != "ghost-parent" for e in graph.edges)


def test_mermaid_has_classes_clicks_edges(tmp_path):
    mermaid = render_mermaid(build_graph(_repo(tmp_path)))
    assert "flowchart LR" in mermaid
    assert "classDef proved" in mermaid
    assert "g_parent --> g_parent_s1" in mermaid
    assert 'click g_parent_s1 "https://github.com/agenticsnz/unsorry/blob/main/goals/parent-s1.lean"' in mermaid
    # Standalone goal (no edges) folds into a per-status cluster, not a forest node.
    assert "g_standalone[" not in mermaid
    assert 'cluster_proved(["proved · 1"])' in mermaid
    assert "class cluster_proved proved;" in mermaid


def test_unconnected_clusters_in_json(tmp_path):
    import json

    payload = json.loads(render_json(build_graph(_repo(tmp_path))))
    groups = {g["status"]: g["ids"] for g in payload["unconnected"]}
    # Only `standalone` (proved) has no decomposition lineage.
    assert groups == {"proved": ["standalone"]}


def test_render_html_hybrid_clusters_expand(tmp_path):
    import json

    html = render_html(build_graph(_repo(tmp_path)))
    # Collapsed, clickable status cluster in the server-rendered initial diagram.
    assert 'cluster_proved(["▸ proved · 1"])' in html
    assert 'call toggleCluster("proved")' in html
    # Client-side expand machinery: a cluster click rebuilds the source as a
    # status subgraph of individual goals and re-renders.
    assert "function buildMermaidSource" in html
    assert "window.toggleCluster" in html
    assert "subgraph sg_" in html
    assert "mermaid.render(" in html
    blob = html.split('id="graph-data">', 1)[1].split("</script>", 1)[0]
    assert json.loads(blob)["unconnected"] == [{"status": "proved", "ids": ["standalone"]}]


def test_render_html_layout_parity(tmp_path):
    # The proof-graph page shares the home/leaderboard card: same heading scale
    # and section insets, and no duplicate leaderboard cross-link (the nav links it).
    html = render_html(build_graph(_repo(tmp_path)))
    assert "text-5xl md:text-7xl" in html and "text-4xl md:text-6xl" not in html
    assert "px-6 md:px-10" in html and "md:px-8" not in html
    assert "Contributor leaderboard" not in html
    assert 'href="leaderboard.html"' in html


def test_markdown_table_lists_every_goal(tmp_path):
    md = render_markdown(build_graph(_repo(tmp_path)))
    for gid in ("parent", "parent-s1", "parent-s2", "standalone"):
        assert f"goals/{gid}.lean" in md
    assert "4 goals" in md
    assert "alice" in md and "`opus`" in md


def test_json_shape(tmp_path):
    import json

    payload = json.loads(render_json(build_graph(_repo(tmp_path))))
    assert len(payload["nodes"]) == 4
    assert {"parent": "open"}.items() <= {n["id"]: n["status"] for n in payload["nodes"]}.items()
    assert len(payload["edges"]) == 2


def test_main_write_and_check(tmp_path, capsys):
    root = _repo(tmp_path)
    assert main(["--write", str(root)]) == 0
    assert (root / "docs" / "proofs-contributors-visualisation.md").exists()
    # Freshly written → check is clean.
    assert main(["--check", str(root)]) == 0
    # Mutate a goal → check reddens.
    _goal(root, "parent", "proved", difficulty=3)
    assert main(["--check", str(root)]) == 1
    assert "stale" in capsys.readouterr().err


def test_main_modes_mutually_exclusive(tmp_path):
    assert main(["--write", "--json", str(tmp_path)]) == 2


def test_parse_prove_log():
    # date \0 author \0 subject
    log = (
        "2026-06-13\x00chat-bit-01\x00prove(cube-eq-triangular-sq-diff): cube_eq_triangular_sq_diff by claude-rmt-001 (#322)\n"
        "2026-06-13\x00Chris Barlow\x00prove(euclid-perfect-numbers): perfect_of_mersenne_prime by p3-a1 (#370)\n"
        "2026-06-12\x00someone\x00prove(cube-eq-triangular-sq-diff): older by x (#100)\n"  # newest wins
        "2026-06-13\x00oma\x00recompose(some-parent): assemble by oma-2-c50d (#371)\n"
        "2026-06-13\x00Chris Barlow\x00docs: roll changelog (#215)\n"  # ignored
    )
    out = parse_prove_log(log)
    cube = out["cube-eq-triangular-sq-diff"]
    assert (cube.agent, cube.pr, cube.date, cube.merged_by) == (
        "claude-rmt-001", "322", "2026-06-13", "chat-bit-01",
    )
    assert out["euclid-perfect-numbers"].merged_by == "Chris Barlow"
    assert out["some-parent"].agent == "oma-2-c50d"
    assert "docs" not in out


def test_build_graph_without_git_is_clean(tmp_path):
    # Fixture trees are not git checkouts → agent/pr stay None, no crash.
    graph = build_graph(_repo(tmp_path))
    assert all(n.agent is None and n.pr is None for n in graph.nodes)


def test_render_html(tmp_path):
    import json

    html = render_html(build_graph(_repo(tmp_path)))
    assert html.startswith("<!doctype html>")
    assert '<pre class="mermaid">' in html and "flowchart LR" in html
    assert 'call showDetail("parent-s1")' in html  # node click → detail panel
    assert 'data-id="standalone"' in html  # every goal is a table row
    assert "mermaid.esm.min.mjs" in html and 'securityLevel: "loose"' in html
    assert re.search(r"__[A-Z]+__", html) is None  # no unreplaced placeholders
    blob = html.split('id="graph-data">', 1)[1].split("</script>", 1)[0]
    assert len(json.loads(blob)["nodes"]) == 4  # embedded model is valid JSON
    # Shared #270 leaderboard design language (ADR-038).
    assert 'name="viewport"' in html  # mobile-friendly
    assert "cdn.tailwindcss.com" in html and "tailwind.config" in html
    assert "brand" in html and "Inter" in html  # brand palette + Inter font
    assert "lg:grid-cols-[minmax(0,1fr)_320px]" in html  # responsive diagram/panel
    assert ">Unsorry<" in html  # shared wordmark header
    assert "4 goals" in html  # header summary stat
    # Issue #738: shared top-nav + click-to-sort goals-table headings.
    assert 'href="index.html"' in html and 'href="leaderboard.html"' in html
    assert 'data-col="0"' in html and 'class="sort-ind"' in html


def test_render_html_status_chips(tmp_path):
    # One header stat chip per present status, carrying the diagram swatch.
    html = render_html(build_graph(_repo(tmp_path)))
    assert "3 proved" in html and "1 open" in html


def test_main_html_stdout(tmp_path, capsys):
    assert main(["--html", str(_repo(tmp_path))]) == 0
    assert capsys.readouterr().out.startswith("<!doctype html>")


def test_render_svg(tmp_path):
    # README preview card (ADR-038), shared leaderboard visual language.
    svg = render_svg(build_graph(_repo(tmp_path)))
    assert svg.startswith("<svg") and svg.rstrip().endswith("</svg>")
    assert "Unsorry Proof Graph" in svg
    assert "Inter, system-ui, sans-serif" in svg  # shared typography
    assert "4 goals" in svg  # summary
    assert ">proved<" in svg  # per-status row
    # Deterministic from statuses alone — git-independent, safe on shallow checkouts.
    assert render_svg(build_graph(_repo(tmp_path))) == svg


def test_main_svg_stdout(tmp_path, capsys):
    assert main(["--svg", str(_repo(tmp_path))]) == 0
    assert capsys.readouterr().out.startswith("<svg")


def test_main_write_and_check_both_artifacts(tmp_path):
    root = _repo(tmp_path)
    assert main(["--write", str(root)]) == 0
    assert (root / "docs" / "proofs-contributors-visualisation.md").exists()
    assert (root / "docs" / "proofs-contributors-visualisation.html").exists()
    assert (root / "docs" / "proof-graph.svg").exists()
    assert main(["--check", str(root)]) == 0
    # Drift in any artifact reddens the check.
    (root / "docs" / "proofs-contributors-visualisation.html").write_text("stale", encoding="utf-8")
    assert main(["--check", str(root)]) == 1
    main(["--write", str(root)])
    (root / "docs" / "proof-graph.svg").write_text("stale", encoding="utf-8")
    assert main(["--check", str(root)]) == 1
