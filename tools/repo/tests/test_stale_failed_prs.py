"""Tests for the stale-failed prove-PR janitor (pure predicates)."""
from __future__ import annotations

from tools.repo.stale_failed_prs import (
    DEFAULT_BRANCH_PREFIX,
    DEFAULT_GATE,
    latest_gate_state,
    normalize_run_state,
    stale_failed_reason,
)

GATE = "gate-a"
PREFIX = "prove/"


# --- normalize_run_state -----------------------------------------------------

def test_normalize_in_flight_uses_status():
    assert normalize_run_state("queued", None) == "queued"
    assert normalize_run_state("in_progress", None) == "in_progress"


def test_normalize_completed_uses_conclusion():
    assert normalize_run_state("completed", "success") == "success"
    assert normalize_run_state("completed", "failure") == "failure"
    assert normalize_run_state("completed", None) == "neutral"  # defensive default


# --- latest_gate_state -------------------------------------------------------

def test_latest_gate_state_absent_is_none():
    assert latest_gate_state(GATE, []) is None
    assert latest_gate_state(GATE, [{"name": "gate-b", "status": "completed",
                                     "conclusion": "failure"}]) is None


def test_latest_gate_state_picks_failed():
    runs = [{"name": "gate-a", "status": "completed", "conclusion": "failure",
             "started_at": "2026-06-22T02:00:00Z"}]
    assert latest_gate_state(GATE, runs) == "failure"


def test_latest_gate_state_takes_latest_run():
    runs = [
        {"name": "gate-a", "status": "completed", "conclusion": "failure",
         "started_at": "2026-06-22T02:00:00Z"},
        {"name": "gate-a", "status": "completed", "conclusion": "success",
         "started_at": "2026-06-22T02:30:00Z"},  # newer re-run wins
    ]
    assert latest_gate_state(GATE, runs) == "success"


# --- stale_failed_reason (the core decision) ---------------------------------

def _reason(gate_state, **kw):
    base = dict(head_ref="prove/foo/mac-158f-abc123", branch_prefix=PREFIX,
                merge_state="BLOCKED", is_draft=False, behind_by=6000,
                min_behind=200, age_minutes=120.0, min_age_minutes=15.0)
    base.update(kw)
    return stale_failed_reason(GATE, gate_state, base["head_ref"],
                               base["branch_prefix"], base["merge_state"],
                               base["is_draft"], base["behind_by"],
                               base["min_behind"], base["age_minutes"],
                               base["min_age_minutes"])


def test_rebase_when_stale_prove_pr_failed_gate():
    # The 2026-06-22 case: a far-behind prove-PR whose gate-a failed on old library.
    r = _reason("failure")
    assert r is not None and "behind base" in r and "gate-a" in r


def test_rebase_on_any_terminal_nonpass():
    assert _reason("failure") is not None
    assert _reason("timed_out") is not None
    assert _reason("cancelled") is not None
    assert _reason("startup_failure") is not None


def test_no_rebase_when_gate_absent():
    # No gate run on the head SHA → that's the dropped-gate janitor's job.
    assert _reason(None) is None


def test_no_rebase_when_gate_passed_or_pending():
    assert _reason("success") is None
    assert _reason("in_progress") is None
    assert _reason("queued") is None


def test_no_rebase_when_branch_current():
    # Below the staleness threshold the failure is REAL, not stale-library; also
    # the loop guard — a just-rebased PR sits near 0 behind.
    assert _reason("failure", behind_by=0) is None
    assert _reason("failure", behind_by=199, min_behind=200) is None


def test_rebase_at_exactly_min_behind():
    assert _reason("failure", behind_by=200, min_behind=200) is not None


def test_no_rebase_when_not_a_prove_branch():
    assert _reason("failure", head_ref="feature/some-fix") is None
    assert _reason("failure", head_ref="docs/origin-story") is None


def test_no_rebase_when_dirty():
    # A conflict can't be auto-rebased clean.
    assert _reason("failure", merge_state="DIRTY") is None


def test_no_rebase_when_too_fresh():
    assert _reason("failure", age_minutes=5.0, min_age_minutes=15.0) is None


def test_no_rebase_when_draft():
    assert _reason("failure", is_draft=True) is None


def test_defaults():
    assert DEFAULT_GATE == "gate-a"
    assert DEFAULT_BRANCH_PREFIX == "prove/"
