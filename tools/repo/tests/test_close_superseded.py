"""Tests for the close-superseded sweep helpers (ADR-058 cleanup)."""
import pytest

from tools.repo.close_superseded import (
    goal_status_from_text,
    is_superseded,
)


@pytest.mark.parametrize(
    "status,expected",
    [
        ("proved", True),
        ("archived", True),
        ("open", False),
        ("translated", False),
        ("blocked", False),
        (None, False),
        ("", False),
    ],
)
def test_is_superseded(status, expected):
    assert is_superseded(status) is expected


def test_goal_status_from_text():
    rec = (
        "𝔸5.1.goal.foo@2026-06-17\n"
        "⟦Ω:Goal⟧{\n  id≜foo\n  phase≜prove\n  status≜proved\n}\n"
    )
    assert goal_status_from_text(rec) == "proved"


def test_goal_status_from_text_open():
    assert goal_status_from_text("⟦Ω:Goal⟧{ status≜open }") == "open"


def test_goal_status_from_text_missing():
    assert goal_status_from_text("no status here") is None
    assert goal_status_from_text(None) is None


def test_only_proved_or_archived_close():
    # The sweep's safety invariant: only proved/archived are superseded, so an
    # open/translated/blocked goal's PR is never closed.
    for live in ("open", "translated", "blocked", "flagged"):
        assert is_superseded(live) is False
