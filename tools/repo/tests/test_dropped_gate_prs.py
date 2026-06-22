"""Tests for the dropped-gate PR janitor (pure predicates)."""
from __future__ import annotations

from tools.repo.dropped_gate_prs import (
    DEFAULT_REQUIRED,
    dropped_gate_reason,
    normalize_run_state,
    present_required,
)

REQ = ("gate-a", "gate-b")


# --- normalize_run_state -----------------------------------------------------

def test_normalize_in_flight_uses_status():
    assert normalize_run_state("queued", None) == "queued"
    assert normalize_run_state("in_progress", None) == "in_progress"
    assert normalize_run_state("waiting", None) == "waiting"


def test_normalize_completed_uses_conclusion():
    assert normalize_run_state("completed", "success") == "success"
    assert normalize_run_state("completed", "failure") == "failure"
    assert normalize_run_state("completed", "cancelled") == "cancelled"
    assert normalize_run_state("completed", None) == "neutral"  # defensive default


# --- present_required --------------------------------------------------------

def test_present_required_keys_only_present_contexts():
    runs = [
        {"name": "gate-a", "status": "completed", "conclusion": "success",
         "started_at": "2026-06-21T02:00:00Z"},
        {"name": "agent-lint", "status": "completed", "conclusion": "success"},
    ]
    # gate-a present (success); gate-b absent (dropped); non-required ignored.
    assert present_required(REQ, runs) == {"gate-a": "success"}


def test_present_required_takes_latest_run_per_context():
    runs = [
        {"name": "gate-a", "status": "completed", "conclusion": "failure",
         "started_at": "2026-06-21T02:00:00Z"},
        {"name": "gate-a", "status": "completed", "conclusion": "success",
         "started_at": "2026-06-21T02:30:00Z"},  # newer re-run wins
    ]
    assert present_required(REQ, runs) == {"gate-a": "success"}


def test_present_required_empty_when_no_runs():
    assert present_required(REQ, []) == {}


# --- dropped_gate_reason (the core decision) ---------------------------------

def _reason(present, **kw):
    base = dict(merge_state="BLOCKED", is_draft=False, behind_by=900,
                age_minutes=120.0, min_age_minutes=30.0)
    base.update(kw)
    return dropped_gate_reason(REQ, present, base["merge_state"], base["is_draft"],
                               base["behind_by"], base["age_minutes"],
                               base["min_age_minutes"])


def test_nudge_when_a_required_gate_is_entirely_absent():
    # The #3394 case: gate-a/gate-b never dispatched on the head SHA.
    r = _reason({})
    assert r is not None and "gate-a" in r and "gate-b" in r


def test_nudge_when_one_gate_passed_and_the_other_dropped():
    r = _reason({"gate-a": "success"})
    assert r is not None and "gate-b" in r and "gate-a" not in r


def test_no_nudge_when_all_gates_present():
    assert _reason({"gate-a": "success", "gate-b": "success"}) is None


def test_no_nudge_when_a_gate_is_pending():
    # A queued/running gate may still report — wait, don't nudge.
    assert _reason({"gate-a": "in_progress"}) is None
    assert _reason({"gate-a": "queued", "gate-b": "success"}) is None


def test_no_nudge_when_a_gate_failed_or_cancelled():
    # Present-but-failed is a real block, not a dropped dispatch.
    assert _reason({"gate-a": "failure"}) is None
    assert _reason({"gate-a": "cancelled", "gate-b": "success"}) is None
    assert _reason({"gate-a": "timed_out"}) is None


def test_no_nudge_when_too_fresh():
    # Within the grace window GitHub may simply not have dispatched yet.
    assert _reason({}, age_minutes=5.0, min_age_minutes=30.0) is None


def test_no_nudge_when_not_behind_base():
    # update-branch can't re-trigger a branch that's already up to date.
    assert _reason({}, behind_by=0) is None


def test_no_nudge_when_draft():
    assert _reason({}, is_draft=True) is None


def test_no_nudge_when_not_blocked():
    assert _reason({}, merge_state="CLEAN") is None
    assert _reason({}, merge_state="DIRTY") is None


def test_nudge_when_unknown_state_with_dropped_gate():
    # A stuck PR often sits UNKNOWN (mergeability never computed because no gate
    # reported) — the dropped-gate signal still applies. #3987 regression.
    r = _reason({}, merge_state="UNKNOWN")
    assert r is not None and "gate-a" in r


def test_default_required_is_gate_a_and_b():
    assert DEFAULT_REQUIRED == ("gate-a", "gate-b")
