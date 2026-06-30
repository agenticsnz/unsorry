"""Tests for the flaky-gate retry janitor (pure predicates)."""
from __future__ import annotations

from tools.repo.flaky_gate_retry import (
    DEFAULT_MAX_ATTEMPTS,
    flaky_retry_reason,
    run_id_from_details_url,
)

REQ = ("gate-a",)


def _reason(present, attempts=None, merge_state="BLOCKED", is_draft=False,
            auto_merge=True, age=60.0, min_age=15.0, max_attempts=3):
    return flaky_retry_reason(REQ, present, attempts or {}, merge_state, is_draft,
                              auto_merge, age, min_age, max_attempts)


# --- run_id_from_details_url -------------------------------------------------

def test_run_id_parsed_from_details_url():
    url = "https://github.com/o/r/actions/runs/28241343907/job/83673093603"
    assert run_id_from_details_url(url) == "28241343907"


def test_run_id_none_when_absent_or_unparseable():
    assert run_id_from_details_url(None) is None
    assert run_id_from_details_url("https://github.com/o/r/pull/42") is None


# --- flaky_retry_reason: the positive case -----------------------------------

def test_retries_a_flaked_gate_with_attempts_left():
    reason, retry = _reason({"gate-a": "failure"}, {"gate-a": 1})
    assert reason is not None and retry == ["gate-a"]
    assert "gate-a" in reason and "1/3" in reason


def test_timed_out_and_cancelled_count_as_flake_retryable():
    for state in ("timed_out", "startup_failure", "cancelled"):
        reason, retry = _reason({"gate-a": state}, {"gate-a": 1})
        assert reason is not None and retry == ["gate-a"], state


# --- bounded: stop at max-attempts -------------------------------------------

def test_stops_retrying_at_max_attempts():
    # run_attempt already == max → not retryable (left BLOCKED for a human).
    reason, retry = _reason({"gate-a": "failure"}, {"gate-a": 3}, max_attempts=3)
    assert reason is None and retry == []


def test_retries_up_to_but_not_including_max():
    reason, _ = _reason({"gate-a": "failure"}, {"gate-a": 2}, max_attempts=3)
    assert reason is not None and "2/3" in reason


# --- conservative guards: leave everything else alone ------------------------

def test_skips_when_auto_merge_disabled():
    assert _reason({"gate-a": "failure"}, {"gate-a": 1}, auto_merge=False) == (None, [])


def test_skips_draft():
    assert _reason({"gate-a": "failure"}, {"gate-a": 1}, is_draft=True) == (None, [])


def test_skips_non_blocked_merge_state():
    assert _reason({"gate-a": "failure"}, {"gate-a": 1}, merge_state="CLEAN") == (None, [])
    # UNKNOWN is accepted (mergeability not yet recomputed).
    r, _ = _reason({"gate-a": "failure"}, {"gate-a": 1}, merge_state="UNKNOWN")
    assert r is not None


def test_skips_passing_gate():
    assert _reason({"gate-a": "success"}, {"gate-a": 1}) == (None, [])


def test_waits_while_a_required_gate_is_still_pending():
    # A gate still in flight may yet pass — don't retry mid-run even if another failed.
    assert _reason({"gate-a": "in_progress"}, {"gate-a": 1}) == (None, [])


def test_skips_too_fresh():
    assert _reason({"gate-a": "failure"}, {"gate-a": 1}, age=5.0, min_age=15.0) == (None, [])


def test_absent_attempt_defaults_to_one():
    # No run_attempt info → treat as the first attempt, so it is retryable.
    reason, retry = _reason({"gate-a": "failure"}, {})
    assert reason is not None and retry == ["gate-a"]


def test_default_max_attempts_is_three():
    assert DEFAULT_MAX_ATTEMPTS == 3
