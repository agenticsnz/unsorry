"""Bounded auto-retry for PRs left BLOCKED by a *flaked* required gate.

The dropped-gate janitor (`tools.repo.dropped_gate_prs`) rescues the case where a
required gate was *never dispatched* (zero check-runs on the head SHA). It
deliberately leaves a gate that *ran and failed* alone — "a real block, not a
drop". But Gate A's replay is a full-Mathlib Lean job and is occasionally flaky:
it runs, fails for an infrastructure reason (runner eviction, cache miss,
timeout), and — because auto-merge is enabled but nothing re-runs a *failed*
gate — the PR sits BLOCKED indefinitely even though the proof is sound and a mere
re-run would pass. Observed 2026-06-29: seven sound `mac-158f` difficulty-1
proofs sat BLOCKED ~63 h on a flaked `gate-a-replay`; re-running made every one
pass and auto-merge.

This is the complement to the janitor: it re-runs the *failed jobs* of a flaked
required gate, **bounded** by the workflow run's `run_attempt` so a genuinely
failing proof stops being retried after `--max-attempts` and stays BLOCKED
(surfaced for a human) rather than looping forever.

  detect: PR open + not draft + auto-merge enabled + mergeStateStatus
          BLOCKED/UNKNOWN + a required gate in a terminal non-pass state +
          no required gate still pending + that gate's run_attempt < max +
          PR older than --min-age-minutes.
  act:    `gh run rerun <run-id> --failed` on the flaked gate's workflow run.

Why the guards:
  * auto-merge OFF → the author is still working; don't burn CI re-running for
    them.
  * a required gate still queued/in_progress → wait; it may yet pass.
  * run_attempt >= max → we have already retried enough; treat as a real failure.
  * too fresh → let the first run finish before retrying.

Re-running a workflow needs an `actions: write` token; run with REFRESH_TOKEN (an
admin PAT / App token) as GH_TOKEN. Without it the workflow degrades to
report-only.

Usage:
  python3 -m tools.repo.flaky_gate_retry            # dry-run: list what would retry
  python3 -m tools.repo.flaky_gate_retry --apply    # rerun --failed (bounded)
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone

from tools.repo.dropped_gate_prs import (
    PENDING_STATES,
    TERMINAL_NONPASS,
    normalize_run_state,
)

# Only Gate A (the heavy, flake-prone replay) is retried by default; Gate B is
# fast hygiene and effectively never flakes. The set is overridable via --required.
DEFAULT_REQUIRED = ("gate-a",)
DEFAULT_MAX_ATTEMPTS = 3  # original run + up to 2 retries, then leave it BLOCKED.


def flaky_retry_reason(required, present_states, attempts, merge_state, is_draft,
                       auto_merge, age_minutes, min_age_minutes, max_attempts):
    """Pure: is this PR a bounded-retry candidate for a flaked required gate?

    Returns ``(reason, contexts_to_retry)`` when it is, else ``(None, [])``.

    ``present_states`` maps required contexts that HAVE a run to their normalized
    state; ``attempts`` maps a context to its workflow run's ``run_attempt`` (how
    many times it has run; absent → 1).
    """
    if is_draft or not auto_merge:
        return None, []
    if merge_state not in ("BLOCKED", "UNKNOWN"):
        return None, []
    # A required gate still in flight might yet pass — wait, don't retry mid-run.
    if any(present_states.get(c) in PENDING_STATES for c in required):
        return None, []
    failed = [c for c in required if present_states.get(c) in TERMINAL_NONPASS]
    if not failed:
        return None, []
    if age_minutes < min_age_minutes:
        return None, []
    # Bounded: only retry gates that have not yet burned through max_attempts.
    retryable = sorted(c for c in failed if attempts.get(c, 1) < max_attempts)
    if not retryable:
        return None, []
    worst = max(attempts.get(c, 1) for c in retryable)
    return (
        f"flaked required gate(s) {', '.join(retryable)} "
        f"(attempt {worst}/{max_attempts}) — re-running failed jobs",
        retryable,
    )


# ---------------------------------------------------------------------------
# I/O shell (thin; the logic above is what's tested)
# ---------------------------------------------------------------------------

_RUN_ID_RE = re.compile(r"/actions/runs/(\d+)")


def run_id_from_details_url(url: str | None) -> str | None:
    """Parse the workflow run id out of a check-run ``details_url`` (pure)."""
    if not url:
        return None
    m = _RUN_ID_RE.search(url)
    return m.group(1) if m else None


def _gh_json(args: list[str], default):
    proc = subprocess.run(["gh", *args], stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True, check=False)
    if proc.returncode != 0:
        print(f"warning: gh {' '.join(args)} failed: {proc.stderr.strip()}",
              file=sys.stderr)
        return default
    return json.loads(proc.stdout or "null") if proc.stdout.strip() else default


def _open_prs(repo: str | None) -> list[dict]:
    args = ["pr", "list", "--state", "open", "--limit", "400", "--json",
            "number,title,headRefOid,isDraft,mergeStateStatus,updatedAt,autoMergeRequest"]
    if repo:
        args += ["--repo", repo]
    return _gh_json(args, []) or []


def _gate_runs(repo: str, sha: str, required) -> dict[str, dict]:
    """Latest check-run per required context on the head SHA, with its state and
    the workflow run id parsed from details_url."""
    arr = _gh_json(["api", f"repos/{repo}/commits/{sha}/check-runs?per_page=100",
                    "--jq", "[.check_runs[] | {name,status,conclusion,started_at,"
                    "details_url}]"], []) or []
    req = set(required)
    latest: dict[str, tuple[str, dict]] = {}
    for r in arr:
        name = r.get("name")
        if name not in req:
            continue
        started = r.get("started_at") or ""
        if name not in latest or started >= latest[name][0]:
            latest[name] = (started, r)
    out = {}
    for name, (_, r) in latest.items():
        out[name] = {
            "state": normalize_run_state(r.get("status"), r.get("conclusion")),
            "run_id": run_id_from_details_url(r.get("details_url")),
        }
    return out


def _run_attempt(repo: str, run_id: str | None) -> int:
    if not run_id:
        return 1
    run = _gh_json(["api", f"repos/{repo}/actions/runs/{run_id}",
                    "--jq", "{run_attempt}"], {})
    return int((run or {}).get("run_attempt", 1) or 1)


def _age_minutes(updated_at: str, now: datetime) -> float:
    try:
        t = datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
    except ValueError:
        return 1e9
    return (now - t).total_seconds() / 60.0


def _rerun_failed(run_id: str) -> bool:
    proc = subprocess.run(["gh", "run", "rerun", run_id, "--failed"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                          text=True, check=False)
    if proc.returncode != 0:
        print(f"  rerun {run_id} failed: {proc.stderr.strip()}", file=sys.stderr)
    return proc.returncode == 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.flaky_gate_retry",
        description="Bounded re-run of PRs left BLOCKED by a flaked required gate.")
    ap.add_argument("--repo", default=None, help="owner/name (default: gh's repo)")
    ap.add_argument("--required", default=",".join(DEFAULT_REQUIRED),
                    help="comma-separated required contexts (default: gate-a)")
    ap.add_argument("--apply", action="store_true", help="rerun (default: dry-run)")
    ap.add_argument("--limit", type=int, default=20, help="max PRs to retry per run")
    ap.add_argument("--min-age-minutes", type=float, default=15.0,
                    help="ignore PRs younger than this")
    ap.add_argument("--max-attempts", type=int, default=DEFAULT_MAX_ATTEMPTS,
                    help="stop retrying once the gate's run_attempt reaches this")
    args = ap.parse_args(argv)

    repo = args.repo
    if not repo:
        repo = (_gh_json(["repo", "view", "--json", "nameWithOwner"], {}) or {}).get(
            "nameWithOwner")
    if not repo:
        print("error: could not determine repo (pass --repo)", file=sys.stderr)
        return 1

    required = tuple(c.strip() for c in args.required.split(",") if c.strip())
    now = datetime.now(timezone.utc)

    candidates: list[tuple[int, str, list[str], dict[str, str]]] = []
    exhausted: list[int] = []
    for pr in _open_prs(repo):
        if pr.get("isDraft") or pr.get("mergeStateStatus") not in ("BLOCKED", "UNKNOWN"):
            continue
        if not pr.get("autoMergeRequest"):
            continue
        sha = pr.get("headRefOid")
        if not sha:
            continue
        gates = _gate_runs(repo, sha, required)
        present = {name: g["state"] for name, g in gates.items()}
        failed = [c for c in required if present.get(c) in TERMINAL_NONPASS]
        if not failed:
            continue
        if any(present.get(c) in PENDING_STATES for c in required):
            continue
        age = _age_minutes(pr.get("updatedAt", ""), now)
        if age < args.min_age_minutes:
            continue
        attempts = {c: _run_attempt(repo, gates[c].get("run_id")) for c in failed}
        reason, retry = flaky_retry_reason(
            required, present, attempts, "BLOCKED", False, True,
            age, args.min_age_minutes, args.max_attempts)
        if reason is None:
            if failed:  # failed but every gate is at/over the attempt cap
                exhausted.append(int(pr["number"]))
            continue
        run_ids = {c: gates[c].get("run_id") for c in retry if gates[c].get("run_id")}
        candidates.append((int(pr["number"]), reason, retry, run_ids))

    capped = candidates[: args.limit]
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"flaky-gate retry: {len(candidates)} flaked-gate block(s), "
          f"acting on {len(capped)} ({mode})")
    if len(candidates) > len(capped):
        print(f"  note: capped at --limit {args.limit}; "
              f"{len(candidates) - len(capped)} left for the next run")
    if exhausted:
        print(f"  note: {len(exhausted)} PR(s) exhausted --max-attempts "
              f"{args.max_attempts} — left BLOCKED for a human: "
              f"{', '.join('#' + str(n) for n in exhausted)}")

    retried = 0
    for number, reason, _retry, run_ids in capped:
        line = f"#{number} — {reason}"
        if not args.apply:
            print(f"  would retry {line}")
            continue
        ok = all(_rerun_failed(rid) for rid in run_ids.values()) if run_ids else False
        if ok:
            retried += 1
            print(f"  retried {line}")
    if args.apply:
        print(f"flaky-gate retry: retried {retried}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
