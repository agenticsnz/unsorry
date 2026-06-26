"""Tests for the merged/closed-PR branch prune."""
from __future__ import annotations

from tools.repo.merged_pr_branches import (
    branch_states,
    is_protected,
    is_prunable,
    select,
)


def test_protected_refs_never_pruned():
    for b in ("main", "claims", "gh-pages", "HEAD",
              "queued/prove/g/agent-1"):
        assert is_protected(b) is True
        assert is_prunable(b, {"MERGED"}) is False


def test_merged_branch_is_prunable():
    assert is_prunable("feature/x", {"MERGED"}) is True
    assert is_prunable("fix/y", {"CLOSED"}) is True
    assert is_prunable("docs/z", {"CLOSED", "MERGED"}) is True


def test_open_pr_branch_is_kept():
    assert is_prunable("feature/live", {"OPEN"}) is False
    assert is_prunable("feature/reopened", {"CLOSED", "OPEN"}) is False  # any OPEN keeps it


def test_branch_without_any_pr_is_left_alone():
    # never had a PR -> not ours to remove (e.g. an in-flight or external branch)
    assert is_prunable("feature/orphan", set()) is False


def test_branch_states_aggregates_multiple_prs():
    prs = [
        {"headRefName": "feature/x", "state": "CLOSED"},
        {"headRefName": "feature/x", "state": "MERGED"},
        {"headRefName": "feature/live", "state": "OPEN"},
        {"headRefName": None, "state": "MERGED"},   # ignored
    ]
    st = branch_states(prs)
    assert st["feature/x"] == {"CLOSED", "MERGED"}
    assert st["feature/live"] == {"OPEN"}
    assert None not in st


def test_select_orders_caps_and_skips_protected_and_open():
    remote = ["feature/b", "feature/a", "feature/live", "main",
              "queued/prove/g/x-1", "feature/orphan"]
    states = {
        "feature/b": {"MERGED"},
        "feature/a": {"MERGED"},
        "feature/live": {"OPEN"},
        "main": {"MERGED"},               # protected → skip
        "queued/prove/g/x-1": {"MERGED"},  # protected prefix → skip
        # feature/orphan: no state → skip
    }
    assert select(remote, states) == ["feature/a", "feature/b"]
    assert select(remote, states, limit=1) == ["feature/a"]
