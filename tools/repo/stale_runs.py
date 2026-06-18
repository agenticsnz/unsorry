"""Stale-run janitor — cancel Gate A runs that are stuck (ADR-058 hygiene).

A Namespace runner that dies mid-job leaves its workflow run wedged `in_progress`
(GitHub never gets the completion signal, so it sits there past the timeout), and
abandoned runs can sit `queued` forever waiting for a runner that will never come.
Either way they keep counting against the submission governor's in-flight budget
(`UNSORRY_MAX_GATE_A_IN_FLIGHT`), starving real verification and triggering
cancellation cascades — the "70 PRs failing" that was really one zombie jam.

This cancels such runs so the in-flight budget reflects *live* work. Conservative
by design: `in_progress` is only stale well past a normal run (default 90 min;
normal incremental Gate A is ~15 min), and `queued` only when it's clearly
abandoned (default 180 min; legitimate queueing waits minutes, not hours) — so it
never kills a genuinely-running or briefly-queued job.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone


def _parse_iso(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def age_minutes(created_at: str, now: datetime) -> float:
    return (now - _parse_iso(created_at)).total_seconds() / 60.0


def is_stale(status: str, created_at: str, now: datetime,
             in_progress_max: float, queued_max: float) -> bool:
    """Pure predicate: a run is stale when its age exceeds the per-status limit."""
    age = age_minutes(created_at, now)
    if status == "in_progress":
        return age > in_progress_max
    if status == "queued":
        return age > queued_max
    return False


def _active_runs(workflow: str, repo: str | None) -> list[dict]:
    runs: list[dict] = []
    for status in ("in_progress", "queued"):
        cmd = ["gh", "run", "list", "--workflow", workflow, "--status", status,
               "--limit", "200", "--json", "databaseId,createdAt,status"]
        if repo:
            cmd += ["--repo", repo]
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              text=True, check=False)
        if proc.returncode != 0:
            print(f"warning: gh run list ({status}) failed: {proc.stderr.strip()}",
                  file=sys.stderr)
            continue
        for r in json.loads(proc.stdout or "[]"):
            r["status"] = status  # gh sometimes blanks status in the list payload
            runs.append(r)
    return runs


def _cancel(run_id: int, repo: str | None) -> bool:
    cmd = ["gh", "run", "cancel", str(run_id)]
    if repo:
        cmd += ["--repo", repo]
    return subprocess.run(cmd, stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL, check=False).returncode == 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.stale_runs",
        description="Cancel Gate A runs stuck in_progress/queued past a limit.")
    ap.add_argument("--workflow", default="gate-a.yml")
    ap.add_argument("--repo", default=None, help="owner/name (default: gh's repo)")
    ap.add_argument("--in-progress-minutes", type=float, default=90.0)
    ap.add_argument("--queued-minutes", type=float, default=180.0)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)

    now = datetime.now(timezone.utc)
    stale = [r for r in _active_runs(args.workflow, args.repo)
             if is_stale(r["status"], r["createdAt"], now,
                         args.in_progress_minutes, args.queued_minutes)]
    cancelled = 0
    for r in stale:
        rid, age = r["databaseId"], age_minutes(r["createdAt"], now)
        if args.dry_run:
            print(f"would cancel {rid} ({r['status']}, {age:.0f}m)")
            continue
        if _cancel(rid, args.repo):
            cancelled += 1
            print(f"cancelled {rid} ({r['status']}, {age:.0f}m)")
        else:
            print(f"failed to cancel {rid}", file=sys.stderr)
    print(f"stale-run janitor: {len(stale)} stale, {cancelled} cancelled "
          f"({args.workflow}; in_progress>{args.in_progress_minutes:.0f}m "
          f"queued>{args.queued_minutes:.0f}m)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
