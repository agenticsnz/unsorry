"""Min-interval debounce guard for the post-merge housekeeping refreshers (ADR-108).

The leaderboard / board / visualisation / ADR-index / attribution-relabel workflows are
``push``-triggered on `main` so they refresh with low latency. That makes them a firehose: ~one
`docs: refresh … [skip ci]` commit per qualifying merge (#6751 §7 B1). This guard lets each keep
its ``push`` trigger but **skip a refresh that already landed within a window**, so the push rate
falls to ≤ ``1/window`` per workflow during sustained activity while the first merge after a quiet
period still refreshes immediately.

Decision rule (``should_skip``) is pure and unit-tested. The "when did we last refresh" lookup
(``last_refresh_epoch``) reads the checked-out git history (every refresher uses
``fetch-depth: 0``). **Fail-open everywhere**: any uncertainty resolves to ``skip=false`` — the
guard may suppress a redundant refresh but must never cause a board to go un-refreshed because the
guard itself failed.

Why a window below the 30-min freshness gate (ADR-098) is safe is argued in ADR-108: the gate's lag
is *commit-time relative*, and the debounce bounds a board's source-relative lag to ≤ ``window``.

Usage (in a workflow, only on ``push`` events):
  python3 -m tools.repo.refresh_debounce --subject "docs: refresh leaderboard" \
      --window-seconds 600 >> "$GITHUB_OUTPUT"
"""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path


def should_skip(
    last_refresh_epoch: int | None, now_epoch: int, window_s: int
) -> bool:
    """True iff a refresh landed strictly within ``window_s`` before ``now_epoch``.

    Fail-open: ``None`` (never refreshed), ``window_s <= 0`` (disabled), an elapsed window, or a
    future ``last_refresh_epoch`` (clock skew, ``now - last < 0``) all return ``False``."""
    if last_refresh_epoch is None or window_s <= 0:
        return False
    age = now_epoch - last_refresh_epoch
    return 0 <= age < window_s


def last_refresh_epoch(root: Path, subject: str) -> int | None:
    """Committer epoch (``%ct``) of the most recent ``HEAD`` commit whose subject contains
    ``subject`` (fixed-string match), or ``None`` if none matches / git is unavailable."""
    try:
        result = subprocess.run(
            ["git", "-C", str(root), "log", "-1", "-F", f"--grep={subject}", "--format=%ct"],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return None
    if result.returncode != 0:
        return None
    out = result.stdout.strip()
    if not out:
        return None
    try:
        return int(out)
    except ValueError:
        return None


def _emit(skip: bool) -> None:
    print(f"skip={'true' if skip else 'false'}")


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    subject: str | None = None
    window_s: int | None = None
    now_epoch: int | None = None
    root = Path.cwd()

    pending = iter(argv)
    for arg in pending:
        if arg == "--subject":
            subject = next(pending, None)
        elif arg.startswith("--subject="):
            subject = arg.split("=", 1)[1]
        elif arg == "--window-seconds":
            raw = next(pending, None)
            window_s = _to_int(raw)
        elif arg.startswith("--window-seconds="):
            window_s = _to_int(arg.split("=", 1)[1])
        elif arg == "--now":
            now_epoch = _to_int(next(pending, None))
        elif arg.startswith("--now="):
            now_epoch = _to_int(arg.split("=", 1)[1])
        elif arg == "--root":
            value = next(pending, None)
            if value is not None:
                root = Path(value)
        elif arg.startswith("--root="):
            root = Path(arg.split("=", 1)[1])
        else:
            print(f"unexpected argument: {arg}", file=sys.stderr)
            return 2

    if not subject:
        print("--subject is required", file=sys.stderr)
        return 2
    if window_s is None or window_s < 0:
        print("--window-seconds requires a non-negative integer", file=sys.stderr)
        return 2

    # Fail-open: a guard that errors must decline to skip, never block a refresh.
    try:
        if now_epoch is None:
            now_epoch = int(time.time())
        skip = should_skip(last_refresh_epoch(root, subject), now_epoch, window_s)
    except Exception:  # noqa: BLE001 — never let the guard turn a refresh red
        _emit(False)
        return 0
    _emit(skip)
    return 0


def _to_int(raw: str | None) -> int | None:
    if raw is None:
        return None
    try:
        return int(raw)
    except ValueError:
        return None


if __name__ == "__main__":
    raise SystemExit(main())
