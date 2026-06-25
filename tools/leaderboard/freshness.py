"""Leaderboard freshness gate — defence-in-depth for issue #6317 (ADR-098).

The regen itself is fast now (ADR-097), so the published board normally tracks
``main`` within minutes. This module is the *visible alarm* for when it does not
— a stuck/queued runner, a lost push race, or a future regression — so the board
can never go **silently** stale (the failure mode issue #6317 called out): it
compares the published ``docs/metrics/leaderboard-ui.json`` ``generated_at``
against the latest board-source commit and fails loudly once the lag crosses a
threshold.

Single source of truth: the "latest board-source commit" is computed by
``generate._latest_source_commit_z`` over ``generate._BOARD_SOURCE_PATHS`` — the
same definition that keys the artifact's ``generated_at`` (SPEC-023-A) — so a
freshly-pushed board reads as lag ≈ 0 and only a genuine publish stall trips the
alarm.

Usage:
  python3 -m tools.leaderboard.freshness [<repo-root>] [--threshold-minutes N]

Exit codes mirror a gate: ``0`` = fresh (or indeterminate — nothing to assert),
``1`` = stale beyond the threshold (also emits a GitHub error annotation), ``2``
= usage error.
"""
from __future__ import annotations

import datetime
import json
import sys
from pathlib import Path

from tools.leaderboard.generate import _latest_source_commit_z

DEFAULT_THRESHOLD_MINUTES = 30
UI_ARTIFACT = Path("docs") / "metrics" / "leaderboard-ui.json"


def _parse_z(ts: str) -> datetime.datetime:
    """Parse an ISO-8601 UTC (``…Z``) timestamp — the form both ``generated_at``
    and ``_latest_source_commit_z`` emit."""
    return datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))


def lag_seconds(generated_at: str, source_commit_z: str) -> int:
    """Non-negative seconds the published board trails the latest source commit.

    Clamped at 0: the generator keys ``generated_at`` to that very commit
    (SPEC-023-A), so a board at or ahead of the latest source is not stale."""
    delta = (_parse_z(source_commit_z) - _parse_z(generated_at)).total_seconds()
    return max(0, int(delta))


def read_generated_at(root: Path) -> str | None:
    """The published board's ``generated_at``, or ``None`` if the artifact is
    absent / unreadable / lacks the field."""
    path = root / UI_ARTIFACT
    if not path.is_file():
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8")).get("generated_at")
    except (ValueError, OSError):
        return None
    return value if isinstance(value, str) else None


def evaluate(root: Path, threshold_s: int) -> tuple[str, int | None, str]:
    """Return ``(status, lag_seconds, human-readable message)``.

    ``status`` is ``"fresh"`` | ``"stale"`` | ``"unknown"``. ``"unknown"`` (the
    artifact or git history is unavailable) is *not* a failure — there is nothing
    to assert against."""
    generated_at = read_generated_at(root)
    source = _latest_source_commit_z(root)
    if generated_at is None or source is None:
        missing = "artifact generated_at" if generated_at is None else "git source history"
        return "unknown", None, f"freshness indeterminate — {missing} unavailable"
    lag = lag_seconds(generated_at, source)
    detail = (
        f"published generated_at={generated_at}; latest board-source commit={source}; "
        f"lag={lag // 60}m{lag % 60:02d}s; threshold={threshold_s // 60}m"
    )
    if lag > threshold_s:
        return "stale", lag, f"leaderboard is STALE — {detail}"
    return "fresh", lag, f"leaderboard is fresh — {detail}"


def _parse_threshold(argv: list[str]) -> tuple[int, list[str]] | None:
    threshold = DEFAULT_THRESHOLD_MINUTES
    rest: list[str] = []
    pending = iter(argv)
    for arg in pending:
        raw: str | None = None
        if arg == "--threshold-minutes":
            raw = next(pending, None)
        elif arg.startswith("--threshold-minutes="):
            raw = arg.split("=", 1)[1]
        else:
            rest.append(arg)
            continue
        if raw is None or not raw.lstrip("-").isdigit() or int(raw) < 0:
            return None
        threshold = int(raw)
    return threshold, rest


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    parsed = _parse_threshold(argv)
    if parsed is None:
        print("--threshold-minutes requires a non-negative integer", file=sys.stderr)
        return 2
    threshold_minutes, rest = parsed
    root = Path(rest[0]) if rest else Path.cwd()
    status, _lag, message = evaluate(root, threshold_minutes * 60)
    if status == "stale":
        # A GitHub Actions error annotation surfaces the stall prominently in the
        # run UI, and the non-zero exit turns the run red — the visible alarm
        # issue #6317 asked for, instead of silently serving a stale board.
        print(f"::error title=Leaderboard stale::{message}")
        print(message, file=sys.stderr)
        return 1
    print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
