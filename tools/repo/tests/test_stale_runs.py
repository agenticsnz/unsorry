from datetime import datetime, timezone

from tools.repo import stale_runs

NOW = datetime(2026, 6, 18, 18, 30, tzinfo=timezone.utc)


def _ago(minutes):
    from datetime import timedelta
    return (NOW - timedelta(minutes=minutes)).strftime("%Y-%m-%dT%H:%M:%SZ")


def test_in_progress_zombie_is_stale():
    # 6h in_progress (the real zombie shape) is stale.
    assert stale_runs.is_stale("in_progress", _ago(360), NOW, 90, 180) is True


def test_in_progress_normal_run_is_not_stale():
    # A ~15 min run mid-flight is NOT touched.
    assert stale_runs.is_stale("in_progress", _ago(15), NOW, 90, 180) is False


def test_in_progress_just_under_limit_kept():
    assert stale_runs.is_stale("in_progress", _ago(89), NOW, 90, 180) is False
    assert stale_runs.is_stale("in_progress", _ago(91), NOW, 90, 180) is True


def test_queued_briefly_is_not_stale():
    # Legitimate queueing (waiting for a runner) must never be cancelled.
    assert stale_runs.is_stale("queued", _ago(45), NOW, 90, 180) is False


def test_queued_abandoned_is_stale():
    # Queued for hours = the runner will never come; abandon it.
    assert stale_runs.is_stale("queued", _ago(240), NOW, 90, 180) is True


def test_completed_status_never_stale():
    assert stale_runs.is_stale("completed", _ago(999), NOW, 90, 180) is False


def test_age_minutes():
    assert round(stale_runs.age_minutes(_ago(90), NOW)) == 90
