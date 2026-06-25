import json
import os
import subprocess
from pathlib import Path

from tools.leaderboard.freshness import (
    evaluate,
    lag_seconds,
    main,
    read_generated_at,
)


def _git(root: Path, *args: str, date: str | None = None) -> None:
    env = os.environ.copy()
    env.update({
        "GIT_AUTHOR_NAME": "T", "GIT_AUTHOR_EMAIL": "t@e.test",
        "GIT_COMMITTER_NAME": "T", "GIT_COMMITTER_EMAIL": "t@e.test",
    })
    if date:
        env["GIT_AUTHOR_DATE"] = date
        env["GIT_COMMITTER_DATE"] = date
    subprocess.run(["git", "-C", str(root), *args], check=True,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)


def _write_ui(root: Path, generated_at: str | None) -> None:
    path = root / "docs" / "metrics"
    path.mkdir(parents=True, exist_ok=True)
    (path / "leaderboard-ui.json").write_text(
        json.dumps({"schema_version": 1, "generated_at": generated_at}) + "\n",
        encoding="utf-8",
    )


def _source_commit(root: Path, goal: str, date: str) -> None:
    """Commit a board-source file (goals/) at a fixed committer time."""
    goals = root / "goals"
    goals.mkdir(parents=True, exist_ok=True)
    (goals / f"{goal}.aisp").write_text(
        f"⟦Ω:Goal⟧{{id≜{goal}; status≜open; difficulty≜1}}\n", encoding="utf-8"
    )
    _git(root, "add", "goals")
    _git(root, "commit", "-m", f"source {goal}", date=date)


# --- pure helpers ------------------------------------------------------------


def test_lag_seconds_counts_board_trailing_source():
    assert lag_seconds("2026-06-25T08:00:00Z", "2026-06-25T08:40:00Z") == 2400


def test_lag_seconds_is_zero_when_board_matches_source():
    assert lag_seconds("2026-06-25T08:40:00Z", "2026-06-25T08:40:00Z") == 0


def test_lag_seconds_clamps_when_board_ahead_of_source():
    # generated_at is keyed to the latest source commit, so "ahead" is not stale.
    assert lag_seconds("2026-06-25T09:00:00Z", "2026-06-25T08:40:00Z") == 0


def test_read_generated_at_handles_missing_and_malformed(tmp_path):
    assert read_generated_at(tmp_path) is None          # no artifact
    _write_ui(tmp_path, None)
    assert read_generated_at(tmp_path) is None          # field is null
    (tmp_path / "docs" / "metrics" / "leaderboard-ui.json").write_text("{", encoding="utf-8")
    assert read_generated_at(tmp_path) is None          # malformed
    _write_ui(tmp_path, "2026-06-25T08:00:00Z")
    assert read_generated_at(tmp_path) == "2026-06-25T08:00:00Z"


# --- evaluate() against real git history -------------------------------------


def test_evaluate_fresh_when_board_within_threshold(tmp_path):
    _git(tmp_path, "init")
    _source_commit(tmp_path, "g", "2026-06-25T08:40:00Z")
    _write_ui(tmp_path, "2026-06-25T08:35:00Z")  # 5 min behind, threshold 30
    status, lag, msg = evaluate(tmp_path, 30 * 60)
    assert status == "fresh"
    assert lag == 300
    assert "fresh" in msg


def test_evaluate_stale_when_board_past_threshold(tmp_path):
    _git(tmp_path, "init")
    _source_commit(tmp_path, "g", "2026-06-25T09:40:00Z")
    _write_ui(tmp_path, "2026-06-25T08:35:00Z")  # 65 min behind
    status, lag, msg = evaluate(tmp_path, 30 * 60)
    assert status == "stale"
    assert lag == 65 * 60
    assert "STALE" in msg


def test_evaluate_unknown_without_artifact_or_git(tmp_path):
    # No git, no artifact → indeterminate, never a false alarm.
    status, lag, _ = evaluate(tmp_path, 30 * 60)
    assert status == "unknown"
    assert lag is None


# --- CLI / exit codes --------------------------------------------------------


def test_main_exit_zero_when_fresh(tmp_path, capsys):
    _git(tmp_path, "init")
    _source_commit(tmp_path, "g", "2026-06-25T08:40:00Z")
    _write_ui(tmp_path, "2026-06-25T08:39:00Z")
    assert main([str(tmp_path)]) == 0
    assert "fresh" in capsys.readouterr().out


def test_main_exit_one_and_annotates_when_stale(tmp_path, capsys):
    _git(tmp_path, "init")
    _source_commit(tmp_path, "g", "2026-06-25T10:00:00Z")
    _write_ui(tmp_path, "2026-06-25T08:00:00Z")
    assert main([str(tmp_path)]) == 1
    out = capsys.readouterr().out
    assert out.startswith("::error title=Leaderboard stale::")


def test_main_threshold_minutes_flag_controls_verdict(tmp_path):
    _git(tmp_path, "init")
    _source_commit(tmp_path, "g", "2026-06-25T09:00:00Z")
    _write_ui(tmp_path, "2026-06-25T08:20:00Z")  # 40 min behind
    assert main([str(tmp_path), "--threshold-minutes", "30"]) == 1   # stale at 30
    assert main([str(tmp_path), "--threshold-minutes=60"]) == 0      # fresh at 60


def test_main_rejects_bad_threshold(tmp_path):
    assert main([str(tmp_path), "--threshold-minutes", "abc"]) == 2
    assert main([str(tmp_path), "--threshold-minutes"]) == 2


def test_main_unknown_state_does_not_fail(tmp_path):
    # Indeterminate (no git / no artifact) must not turn the run red.
    assert main([str(tmp_path)]) == 0
