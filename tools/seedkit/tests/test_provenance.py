"""seedkit provenance + difficulty contract (ADR-086 / SPEC-086-A).

Every fixture is attributed to an authenticated solver and an honest Lean engine
(`provider≜lean`, `model≜decide`/`ring`), and every family rates its
template/one-tactic goals at the sourcing rubric's honest difficulty (1) — never
anonymous, never the inflated 3..5 self-tag, never a bespoke `seedkit` provider.
"""

from __future__ import annotations

import importlib

import pytest

import _artifact


def _write_min(tmp_path, monkeypatch, **over):
    """Drive `write_artifacts` directly in an isolated cwd with minimal inputs."""
    monkeypatch.chdir(tmp_path)
    kw = dict(
        gid="demo-goal",
        name="demo_goal",
        goal_lean="import Mathlib\n\ntheorem demo_goal : True := by\n  sorry\n",
        proof="import Mathlib\n\ntheorem demo_goal : True := by trivial\n",
        summary="demo",
        source="demo",
        reference="demo",
        difficulty=1,
        delta="0.60",
        model="decide",
    )
    kw.update(over)
    return _artifact.write_artifacts(**kw)


def _records(tmp_path, line):
    gid, _name, _mod, sha = line.split("|")
    goal = (tmp_path / "goals" / f"{gid}.aisp").read_text()
    index = (tmp_path / "library" / "index" / f"{sha}.aisp").read_text()
    return goal, index


def test_solver_required_no_anon(tmp_path, monkeypatch):
    monkeypatch.delenv("UNSORRY_SOLVER", raising=False)
    monkeypatch.delenv("SEEDKIT_SOLVER", raising=False)
    with pytest.raises(ValueError, match="anonymous provenance"):
        _write_min(tmp_path, monkeypatch)


def test_unsorry_solver_preferred_over_seedkit_solver(tmp_path, monkeypatch):
    monkeypatch.setenv("UNSORRY_SOLVER", "alice")
    monkeypatch.setenv("SEEDKIT_SOLVER", "bob")
    _, index = _records(tmp_path, _write_min(tmp_path, monkeypatch))
    assert "solver≜alice" in index


def test_seedkit_solver_fallback(tmp_path, monkeypatch):
    monkeypatch.delenv("UNSORRY_SOLVER", raising=False)
    monkeypatch.setenv("SEEDKIT_SOLVER", "bob")
    _, index = _records(tmp_path, _write_min(tmp_path, monkeypatch))
    assert "solver≜bob" in index


def test_honest_engine_and_difficulty(tmp_path, monkeypatch):
    monkeypatch.setenv("UNSORRY_SOLVER", "alice")
    goal, index = _records(
        tmp_path, _write_min(tmp_path, monkeypatch, difficulty=1, model="ring")
    )
    assert "difficulty≜1" in goal
    assert "provider≜lean" in index
    assert "model≜ring" in index
    assert "provider≜seedkit" not in index
    assert "template-" not in index


@pytest.mark.parametrize(
    "module, call, model",
    [
        ("mkfiles", lambda m: m.write_goal(12, 6, 4), "decide"),
        ("mkfiles_altgeom", lambda m: m.write_goal(3), "ring"),
    ],
)
def test_family_writers_are_honest(tmp_path, monkeypatch, module, call, model):
    """A representative `decide` family and `ring` family both emit honest,
    identity-bearing provenance and difficulty 1 end-to-end."""
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("UNSORRY_SOLVER", "alice")
    goal, index = _records(tmp_path, call(importlib.import_module(module)))
    assert "difficulty≜1" in goal
    assert "provider≜lean" in index
    assert f"model≜{model}" in index
    assert "solver≜alice" in index
    assert "template-" not in index
