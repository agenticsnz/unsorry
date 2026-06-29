"""Tests for the stale queued-branch janitor (pure predicates)."""
from __future__ import annotations

from pathlib import Path

from tools.repo.stale_branches import done_goals, goal_of_branch, is_stale


def test_goal_of_branch_extracts_goal():
    assert goal_of_branch("queued/prove/gpow-diff-two-pow-fifteen/mac-158f-5a5940") \
        == "gpow-diff-two-pow-fifteen"


def test_goal_of_branch_rejects_non_queued():
    assert goal_of_branch("feature/goal-x-unblock-agent-abc123") is None
    assert goal_of_branch("queued/prove/onlygoal") is None  # missing agent segment
    assert goal_of_branch("main") is None


def test_is_stale_only_when_goal_done():
    done = {"g1", "g2"}
    assert is_stale("queued/prove/g1/agent-aaa111", done) is True
    assert is_stale("queued/prove/g3/agent-bbb222", done) is False  # open goal
    assert is_stale("feature/goal-g1-x", done) is False              # not a queued branch


def _goal(root: Path, name: str, status: str) -> None:
    (root / "goals").mkdir(parents=True, exist_ok=True)
    (root / "goals" / f"{name}.aisp").write_text(
        f"𝔸5.1.goal.{name}@2026-06-14\n"
        "γ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{id≜{name}; phase≜prove; status≜{status}}}\n",
        encoding="utf-8",
    )


def test_done_goals_collects_proved_and_archived_only(tmp_path: Path):
    _goal(tmp_path, "proved-one", "proved")
    _goal(tmp_path, "archived-one", "archived")
    _goal(tmp_path, "open-one", "open")
    _goal(tmp_path, "blocked-one", "blocked")
    assert done_goals(tmp_path) == {"proved-one", "archived-one"}


def test_done_goals_empty_when_no_goals_dir(tmp_path: Path):
    assert done_goals(tmp_path) == set()


def test_is_stale_end_to_end_with_done_goals(tmp_path: Path):
    _goal(tmp_path, "done", "archived")
    _goal(tmp_path, "pending", "open")
    done = done_goals(tmp_path)
    assert is_stale("queued/prove/done/agent-abc123", done) is True
    assert is_stale("queued/prove/pending/agent-abc123", done) is False
