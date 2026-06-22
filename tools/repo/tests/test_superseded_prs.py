"""Tests for the superseded-PR janitor (pure predicates)."""
from __future__ import annotations

from pathlib import Path

from tools.repo.superseded_prs import (
    decomposed_goals,
    goal_statuses,
    is_superseded,
    parse_pr_action,
)


def test_parse_pr_action():
    assert parse_pr_action("decompose(sq-add-sq-eq-three-mul-sq-s4): 3 sub-lemmas") \
        == ("decompose", "sq-add-sq-eq-three-mul-sq-s4")
    assert parse_pr_action("prove(gzmod-12-pow): foo by mac-158f (#1)") \
        == ("prove", "gzmod-12-pow")
    assert parse_pr_action("unblock(sum-icc-choose-hockey-stick): subs proved") \
        == ("unblock", "sum-icc-choose-hockey-stick")


def test_parse_pr_action_ignores_non_coordination():
    assert parse_pr_action("docs(adr): ADR-080 …") is None
    assert parse_pr_action("affinity(g): -10") is None       # not in scope
    assert parse_pr_action("") is None


def test_is_superseded_prove():
    st = {"g": "archived", "h": "open"}
    assert is_superseded("prove", "g", set(), st) is True       # archived → done
    assert is_superseded("prove", "h", set(), st) is False      # still open
    assert is_superseded("prove", "unknown", set(), st) is False  # conservative


def test_is_superseded_decompose():
    assert is_superseded("decompose", "g", {"g"}, {}) is True    # already decomposed
    assert is_superseded("decompose", "g", set(), {}) is False   # not yet


def test_is_superseded_unblock():
    assert is_superseded("unblock", "g", set(), {"g": "blocked"}) is False  # still needed
    assert is_superseded("unblock", "g", set(), {"g": "open"}) is True      # no longer blocked
    assert is_superseded("unblock", "g", set(), {"g": "proved"}) is True
    assert is_superseded("unblock", "g", set(), {}) is False                # unknown → leave


def test_unrecognised_action_never_superseded():
    assert is_superseded("affinity", "g", {"g"}, {"g": "proved"}) is False


def _goal(root: Path, name: str, status: str) -> None:
    (root / "goals").mkdir(parents=True, exist_ok=True)
    (root / "goals" / f"{name}.aisp").write_text(
        f"⟦Ω:Goal⟧{{id≜{name}; phase≜prove; status≜{status}}}\n", encoding="utf-8")


def _decomp(root: Path, parent: str, agent: str) -> None:
    (root / "decompositions").mkdir(parents=True, exist_ok=True)
    (root / "decompositions" / f"{parent}.{agent}.aisp").write_text(
        f"⟦Ω:Decomp⟧{{parent≜{parent}; agent≜{agent}}}\n", encoding="utf-8")


def test_state_readers(tmp_path: Path):
    _goal(tmp_path, "a", "proved")
    _goal(tmp_path, "b", "blocked")
    _decomp(tmp_path, "b", "beast-4444")
    assert goal_statuses(tmp_path) == {"a": "proved", "b": "blocked"}
    assert decomposed_goals(tmp_path) == {"b"}


def test_end_to_end_decompose_superseded(tmp_path: Path):
    # The #3208/#3186/#3171 case: goal blocked + already decomposed → close.
    _goal(tmp_path, "sq4", "blocked")
    _decomp(tmp_path, "sq4", "beast-4444")
    dec, st = decomposed_goals(tmp_path), goal_statuses(tmp_path)
    assert is_superseded("decompose", "sq4", dec, st) is True
