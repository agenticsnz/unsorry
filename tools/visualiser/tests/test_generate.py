"""Proof-graph visualiser tests (ADR-032). Fixture AISP tree — no network."""
from __future__ import annotations

from pathlib import Path

from tools.visualiser.generate import (
    build_graph,
    main,
    parse_prove_log,
    render_json,
    render_markdown,
    render_mermaid,
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
    # Standalone goal (no edges) is not drawn in the forest.
    assert "g_standalone[" not in mermaid


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
    assert (root / "docs" / "graph.md").exists()
    # Freshly written → check is clean.
    assert main(["--check", str(root)]) == 0
    # Mutate a goal → check reddens.
    _goal(root, "parent", "proved", difficulty=3)
    assert main(["--check", str(root)]) == 1
    assert "stale" in capsys.readouterr().err


def test_main_modes_mutually_exclusive(tmp_path):
    assert main(["--write", "--json", str(tmp_path)]) == 2


def test_parse_prove_log():
    log = (
        "2026-06-13\x00prove(cube-eq-triangular-sq-diff): cube_eq_triangular_sq_diff by claude-rmt-001 (#322)\n"
        "2026-06-13\x00prove(euclid-perfect-numbers): perfect_of_mersenne_prime by p3-a1 (#370)\n"
        "2026-06-12\x00prove(cube-eq-triangular-sq-diff): older by someone-else (#100)\n"  # newest wins
        "2026-06-13\x00recompose(some-parent): assemble by oma-2-c50d (#371)\n"
        "2026-06-13\x00docs: roll changelog (#215)\n"  # ignored
    )
    out = parse_prove_log(log)
    assert out["cube-eq-triangular-sq-diff"] == ("claude-rmt-001", "322", "2026-06-13")
    assert out["euclid-perfect-numbers"] == ("p3-a1", "370", "2026-06-13")
    assert out["some-parent"] == ("oma-2-c50d", "371", "2026-06-13")
    assert "docs" not in out


def test_build_graph_without_git_is_clean(tmp_path):
    # Fixture trees are not git checkouts → agent/pr stay None, no crash.
    graph = build_graph(_repo(tmp_path))
    assert all(n.agent is None and n.pr is None for n in graph.nodes)
