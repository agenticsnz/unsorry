"""Tests for the post-merge refresh debounce guard (SPEC-108-A)."""
from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from tools.repo import refresh_debounce as rd

WINDOW = 600  # 10 min


# --------------------------------------------------------------------------- #
# should_skip — pure decision rule
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    "last, now, window, expected",
    [
        (None, 1000, WINDOW, False),            # never refreshed -> refresh
        (1000, 1300, WINDOW, True),             # 300s ago, inside window -> skip
        (1000, 1000, WINDOW, True),             # 0s ago -> skip
        (1000, 1000 + WINDOW, WINDOW, False),   # exactly at window -> refresh
        (1000, 1000 + WINDOW + 1, WINDOW, False),  # past window -> refresh
        (1000, 1300, 0, False),                 # window disabled -> refresh
        (1000, 1300, -5, False),                # negative window -> refresh
        (2000, 1000, WINDOW, False),            # future last (clock skew) -> refresh
    ],
)
def test_should_skip(last, now, window, expected):
    assert rd.should_skip(last, now, window) is expected


# --------------------------------------------------------------------------- #
# last_refresh_epoch — git lookup
# --------------------------------------------------------------------------- #
def _git(root: Path, *args: str, epoch: int | None = None) -> None:
    env = None
    if epoch is not None:
        env = {
            "GIT_AUTHOR_DATE": f"@{epoch} +0000",
            "GIT_COMMITTER_DATE": f"@{epoch} +0000",
        }
    subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        text=True,
        env={**_base_env(), **(env or {})},
    )


def _base_env() -> dict[str, str]:
    import os

    return {
        **os.environ,
        "GIT_AUTHOR_NAME": "t",
        "GIT_AUTHOR_EMAIL": "t@t",
        "GIT_COMMITTER_NAME": "t",
        "GIT_COMMITTER_EMAIL": "t@t",
    }


def _commit(root: Path, subject: str, epoch: int) -> None:
    (root / "f").write_text(str(epoch), encoding="utf-8")
    _git(root, "add", "f")
    _git(root, "commit", "-m", subject, epoch=epoch)


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    _git(tmp_path, "init", "-q")
    return tmp_path


def test_last_refresh_epoch_returns_most_recent_match(repo: Path):
    _commit(repo, "docs: refresh leaderboard [skip ci]", 1000)
    _commit(repo, "prove(some-goal) by mac", 1500)  # unrelated, newer
    _commit(repo, "docs: refresh leaderboard [skip ci]", 2000)  # newest match
    _commit(repo, "docs: refresh targets board [skip ci]", 2500)  # different subject
    assert rd.last_refresh_epoch(repo, "docs: refresh leaderboard") == 2000


def test_last_refresh_epoch_none_when_no_match(repo: Path):
    _commit(repo, "prove(x) by y", 1000)
    assert rd.last_refresh_epoch(repo, "docs: refresh leaderboard") is None


def test_last_refresh_epoch_none_when_not_a_repo(tmp_path: Path):
    assert rd.last_refresh_epoch(tmp_path / "nope", "docs: refresh leaderboard") is None


def test_last_refresh_epoch_fixed_string_not_regex(repo: Path):
    # A subject containing regex metacharacters must match literally (-F).
    _commit(repo, "docs: refresh ADR index [skip ci]", 1000)
    assert rd.last_refresh_epoch(repo, "docs: refresh ADR index") == 1000
    # ".*" would match anything as a regex but must not as a fixed string.
    assert rd.last_refresh_epoch(repo, ".*refresh.*") is None


# --------------------------------------------------------------------------- #
# main — CLI wiring
# --------------------------------------------------------------------------- #
def test_main_skips_inside_window(repo: Path, capsys):
    _commit(repo, "docs: refresh leaderboard [skip ci]", 10_000)
    rc = rd.main(
        ["--subject", "docs: refresh leaderboard", "--window-seconds", "600",
         "--now", "10_300".replace("_", ""), "--root", str(repo)]
    )
    assert rc == 0
    assert capsys.readouterr().out.strip() == "skip=true"


def test_main_refreshes_outside_window(repo: Path, capsys):
    _commit(repo, "docs: refresh leaderboard [skip ci]", 10_000)
    rc = rd.main(
        ["--subject", "docs: refresh leaderboard", "--window-seconds", "600",
         "--now", "11000", "--root", str(repo)]
    )
    assert rc == 0
    assert capsys.readouterr().out.strip() == "skip=false"


def test_main_refreshes_when_no_prior(repo: Path, capsys):
    _commit(repo, "prove(x) by y", 10_000)
    rc = rd.main(
        ["--subject", "docs: refresh leaderboard", "--window-seconds", "600",
         "--now", "10100", "--root", str(repo)]
    )
    assert rc == 0
    assert capsys.readouterr().out.strip() == "skip=false"


def test_main_window_zero_disables(repo: Path, capsys):
    _commit(repo, "docs: refresh leaderboard [skip ci]", 10_000)
    rc = rd.main(
        ["--subject", "docs: refresh leaderboard", "--window-seconds", "0",
         "--now", "10001", "--root", str(repo)]
    )
    assert rc == 0
    assert capsys.readouterr().out.strip() == "skip=false"


def test_main_fail_open_when_not_a_repo(tmp_path: Path, capsys):
    rc = rd.main(
        ["--subject", "docs: refresh leaderboard", "--window-seconds", "600",
         "--now", "100", "--root", str(tmp_path / "nope")]
    )
    assert rc == 0
    assert capsys.readouterr().out.strip() == "skip=false"


@pytest.mark.parametrize(
    "argv",
    [
        ["--window-seconds", "600"],                       # no subject
        ["--subject", "x"],                                # no window
        ["--subject", "x", "--window-seconds", "-1"],      # negative window
        ["--subject", "x", "--window-seconds", "abc"],     # non-int window
        ["--subject", "x", "--window-seconds", "600", "--bogus"],  # unknown arg
    ],
)
def test_main_usage_errors(argv, capsys):
    assert rd.main(argv) == 2
