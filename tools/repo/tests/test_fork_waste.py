"""Tests for the duplicate-verifier-waste metric (ADR-070 / SPEC-070-A)."""
from __future__ import annotations

import io
import json

from tools.repo import fork_waste as fw


def _pr(number=1, goal="g", cross=True, state="MERGED", merged=True):
    return {
        "number": number,
        "title": f"prove({goal}): thm by a",
        "isCrossRepository": cross,
        "state": state,
        "mergedAt": "2026-06-18T00:00:00Z" if merged else None,
    }


def test_prove_goal_extraction():
    assert fw.prove_goal("prove(my-goal-s1): t by a") == "my-goal-s1"
    assert fw.prove_goal("docs: x") is None
    assert fw.prove_goal("chore(sourcing): y") is None
    assert fw.prove_goal("") is None


def test_non_prove_titles_ignored():
    prs = [{"title": "docs: x", "isCrossRepository": True, "state": "CLOSED", "mergedAt": None}]
    s = fw.summarize(prs)
    assert s["prove_prs"] == 0 and s["fork_prove_prs"] == 0


def test_closed_unmerged_fork_is_waste():
    prs = [
        _pr(1, "g", cross=True, state="MERGED", merged=True),    # the winner
        _pr(2, "g", cross=True, state="CLOSED", merged=False),   # wasted
        _pr(3, "g", cross=True, state="CLOSED", merged=False),   # wasted
    ]
    s = fw.summarize(prs)
    assert s["fork_prove_prs"] == 3
    assert s["fork_merged"] == 1
    assert s["fork_closed_unmerged"] == 2
    assert s["estimated_wasted_gate_a_runs"] == 2
    assert s["fork_waste_ratio"] == round(2 / 3, 4)


def test_open_and_merged_are_not_waste():
    prs = [
        _pr(1, "g", state="OPEN", merged=False),
        _pr(2, "g", state="MERGED", merged=True),
    ]
    s = fw.summarize(prs)
    assert s["fork_open"] == 1
    assert s["fork_merged"] == 1
    assert s["fork_closed_unmerged"] == 0


def test_non_fork_prove_prs_counted_but_not_fork_waste():
    prs = [
        _pr(1, "g", cross=False, state="CLOSED", merged=False),  # same-repo, not fork waste
        _pr(2, "g", cross=True, state="CLOSED", merged=False),   # fork waste
    ]
    s = fw.summarize(prs)
    assert s["prove_prs"] == 2
    assert s["fork_prove_prs"] == 1
    assert s["fork_closed_unmerged"] == 1


def test_zero_division_guarded():
    s = fw.summarize([])
    assert s["fork_waste_ratio"] == 0.0
    assert s["estimated_wasted_gate_a_runs"] == 0
    assert s["top_collisions"] == []


def test_collision_counting_and_ordering():
    prs = [
        _pr(1, "lonely", cross=True, state="MERGED", merged=True),       # single PR, no collision
        _pr(2, "busy", cross=True, state="MERGED", merged=True),
        _pr(3, "busy", cross=True, state="CLOSED", merged=False),
        _pr(4, "busy", cross=True, state="CLOSED", merged=False),        # busy: 3 PRs
        _pr(5, "pair", cross=True, state="MERGED", merged=True),
        _pr(6, "pair", cross=False, state="CLOSED", merged=False),       # pair: 2 PRs, 1 fork
    ]
    s = fw.summarize(prs)
    assert s["goals_with_multiple_prove_prs"] == 2          # busy, pair
    assert s["goals_with_fork_collision"] == 2
    assert [c["goal"] for c in s["top_collisions"]] == ["busy", "pair"]
    assert s["top_collisions"][0]["prove_prs"] == 3


def test_top_collisions_capped(monkeypatch):
    monkeypatch.setattr(fw, "TOP_COLLISIONS", 2)
    prs = []
    for g in ("a", "b", "c"):
        prs += [_pr(goal=g, state="MERGED", merged=True), _pr(goal=g, state="CLOSED", merged=False)]
    s = fw.summarize(prs)
    assert len(s["top_collisions"]) == 2


def test_cli_summarize_stdout(monkeypatch):
    prs = [_pr(1, "g", state="CLOSED", merged=False)]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(prs)))
    out = io.StringIO()
    monkeypatch.setattr("sys.stdout", out)
    assert fw.main(["summarize"]) == 0
    assert json.loads(out.getvalue())["fork_closed_unmerged"] == 1


def test_cli_write(tmp_path, monkeypatch):
    prs = [_pr(1, "g", state="CLOSED", merged=False)]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(prs)))
    monkeypatch.setattr("sys.stderr", io.StringIO())
    dest = tmp_path / "fork-waste.json"
    assert fw.main(["summarize", "--write", str(dest)]) == 0
    assert json.loads(dest.read_text())["fork_closed_unmerged"] == 1


def test_cli_bad_json_is_zero(monkeypatch):
    monkeypatch.setattr("sys.stdin", io.StringIO("not json"))
    out = io.StringIO()
    monkeypatch.setattr("sys.stdout", out)
    assert fw.main(["summarize"]) == 0
    assert json.loads(out.getvalue())["prove_prs"] == 0


def test_cli_usage():
    assert fw.main([]) == 2
    assert fw.main(["bogus"]) == 2
