"""Nudge PRs that GitHub left BLOCKED by a dropped required-check dispatch.

GitHub occasionally fails to dispatch the `pull_request` workflows when a PR is
opened: the required checks (`gate-a` / `gate-b`) are never created on the head
SHA, so they can never report and the PR sits `BLOCKED` forever — auto-merge
enabled but unable to fire. With no new commit, nothing re-triggers them. (Seen
on #3394, stuck ~7 h, 927 commits behind.)

This finds that exact pathology and re-triggers it by updating the PR branch with
its base, which fires a fresh `pull_request` synchronize and dispatches the gates.

  detect: PR open + not draft + mergeStateStatus BLOCKED or UNKNOWN + a required
          context has ZERO check-runs on the head SHA (not pending, not failed —
          absent).

Conservative — it acts only on a POSITIVE dropped-dispatch signal and leaves
everything else alone:
  * a required gate that is queued/in_progress/action_required → still might
    report, so WAIT (no action);
  * a required gate that failed/cancelled/timed-out → a real block, not a drop;
  * a PR younger than --min-age-minutes → give GitHub time to dispatch first;
  * a branch not behind its base → `update-branch` can't re-trigger it, so report
    for manual handling rather than loop.

The branch update must NOT use the default GITHUB_TOKEN: events it triggers do
not start new workflow runs, so the gates would stay un-dispatched. Run with an
admin PAT / App token (REFRESH_TOKEN) as GH_TOKEN so the synchronize event is
attributed to a real actor and the gates actually run. Without it, the workflow
degrades to report-only.

Usage:
  python3 -m tools.repo.dropped_gate_prs            # dry-run: list what would nudge
  python3 -m tools.repo.dropped_gate_prs --apply    # update-branch (bounded)
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone

# A check-run whose required gate is in one of these is NOT a dropped dispatch.
PENDING_STATES = frozenset(
    {"queued", "in_progress", "waiting", "requested", "pending", "action_required"}
)
# Terminal, non-success states: the gate ran and didn't pass — a real block, or a
# deliberate/transient cancellation. Either way it is present, not dropped.
TERMINAL_NONPASS = frozenset(
    {"failure", "timed_out", "startup_failure", "cancelled", "action_required"}
)

DEFAULT_REQUIRED = ("gate-a", "gate-b")


def normalize_run_state(status: str | None, conclusion: str | None) -> str:
    """A check-run's status+conclusion → one normalized token.

    In-flight runs (status != completed) normalize to their status; completed
    runs normalize to their conclusion. Pure.
    """
    if (status or "") != "completed":
        return (status or "pending").lower()
    return (conclusion or "neutral").lower()


def present_required(required, runs) -> dict[str, str]:
    """Map each required context that has >=1 check-run on the head SHA to its
    most-recent normalized state. Absent required contexts are simply not keyed.

    `runs` is an iterable of dicts with name/status/conclusion (+ optional
    started_at to pick the latest when a context has several runs). Pure.
    """
    req = set(required)
    latest: dict[str, tuple[str, str]] = {}  # name -> (started_at, state)
    for r in runs:
        name = r.get("name")
        if name not in req:
            continue
        started = r.get("started_at") or ""
        state = normalize_run_state(r.get("status"), r.get("conclusion"))
        if name not in latest or started >= latest[name][0]:
            latest[name] = (started, state)
    return {name: state for name, (_, state) in latest.items()}


def dropped_gate_reason(required, present_states, merge_state, is_draft,
                        behind_by, age_minutes, min_age_minutes) -> str | None:
    """Pure: is this PR a nudge-able dropped-gate block? Returns a human reason
    string when it is, else None. See the module docstring for each guard.

    `present_states` maps the required contexts that HAVE a run to their state.
    """
    if is_draft:
        return None
    # BLOCKED is the normal dropped-gate state, but a stuck PR often sits in
    # UNKNOWN — GitHub never (re)computed its mergeability because no required
    # check ever reported. #3987 sat UNKNOWN for 6 h and the BLOCKED-only filter
    # skipped it every run. The gate-absence signal below is what actually proves
    # a dropped dispatch, so accept either state. (CLEAN/UNSTABLE/DIRTY/BEHIND
    # are real merge states with their gates present, so they fall through.)
    if merge_state not in ("BLOCKED", "UNKNOWN"):
        return None
    missing = sorted(c for c in required if c not in present_states)
    if not missing:
        return None                                   # every gate dispatched
    if any(present_states.get(c) in TERMINAL_NONPASS for c in required):
        return None                                   # a present gate failed/was cancelled
    if any(present_states.get(c) in PENDING_STATES for c in required):
        return None                                   # a present gate may still report
    if age_minutes < min_age_minutes:
        return None                                   # too fresh; let GitHub dispatch
    if behind_by <= 0:
        return None                                   # update-branch can't re-trigger
    return f"required check(s) never dispatched on head SHA: {', '.join(missing)}"


# ---------------------------------------------------------------------------
# I/O shell (thin; the logic above is what's tested)
# ---------------------------------------------------------------------------

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
            "number,title,headRefOid,isDraft,mergeStateStatus,updatedAt"]
    if repo:
        args += ["--repo", repo]
    return _gh_json(args, []) or []


def _check_run_states(repo: str, sha: str, required) -> dict[str, str]:
    # One bounded fetch (a head SHA carries well under 100 check-runs); the array
    # `--jq` yields a single JSON array so it parses cleanly.
    arr = _gh_json(["api", f"repos/{repo}/commits/{sha}/check-runs?per_page=100",
                    "--jq", "[.check_runs[] | {name,status,conclusion,started_at}]"], [])
    return present_required(required, arr or [])


def _behind_by(repo: str, base: str, sha: str) -> int:
    cmp = _gh_json(["api", f"repos/{repo}/compare/{base}...{sha}",
                    "--jq", "{behind_by}"], {})
    return int((cmp or {}).get("behind_by", 0))


def _age_minutes(updated_at: str, now: datetime) -> float:
    try:
        t = datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
    except ValueError:
        return 1e9
    return (now - t).total_seconds() / 60.0


def _update_branch(repo: str, number: int) -> bool:
    proc = subprocess.run(
        ["gh", "api", "--method", "PUT",
         f"repos/{repo}/pulls/{number}/update-branch"],
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True, check=False)
    if proc.returncode != 0:
        print(f"  update-branch #{number} failed: {proc.stderr.strip()}",
              file=sys.stderr)
    return proc.returncode == 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.dropped_gate_prs",
        description="Re-trigger PRs left BLOCKED by a dropped required-check dispatch.")
    ap.add_argument("--repo", default=None, help="owner/name (default: gh's repo)")
    ap.add_argument("--base", default="main", help="base branch (default: main)")
    ap.add_argument("--required", default=",".join(DEFAULT_REQUIRED),
                    help="comma-separated required contexts (default: gate-a,gate-b)")
    ap.add_argument("--apply", action="store_true", help="update-branch (default: dry-run)")
    ap.add_argument("--limit", type=int, default=20, help="max PRs to nudge per run")
    ap.add_argument("--min-age-minutes", type=float, default=30.0,
                    help="ignore PRs younger than this (let GitHub dispatch first)")
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

    nudged_candidates: list[tuple[int, str, str]] = []  # (number, title, reason)
    blocked_not_behind: list[int] = []
    for pr in _open_prs(repo):
        if pr.get("isDraft") or pr.get("mergeStateStatus") not in ("BLOCKED", "UNKNOWN"):
            continue
        sha = pr.get("headRefOid")
        if not sha:
            continue
        present = _check_run_states(repo, sha, required)
        # Cheap pre-check before the (extra) compare call: only proceed if a
        # required context is absent and none present is failed/pending.
        missing = [c for c in required if c not in present]
        if not missing:
            continue
        if any(present.get(c) in TERMINAL_NONPASS for c in required):
            continue
        if any(present.get(c) in PENDING_STATES for c in required):
            continue
        age = _age_minutes(pr.get("updatedAt", ""), now)
        if age < args.min_age_minutes:
            continue
        behind = _behind_by(repo, args.base, sha)
        reason = dropped_gate_reason(required, present, "BLOCKED", False,
                                     behind, age, args.min_age_minutes)
        if reason is None:
            if behind <= 0:
                blocked_not_behind.append(int(pr["number"]))
            continue
        nudged_candidates.append((int(pr["number"]), pr.get("title", ""), reason))

    capped = nudged_candidates[: args.limit]
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"dropped-gate janitor: {len(nudged_candidates)} dropped-gate block(s), "
          f"acting on {len(capped)} ({mode})")
    if len(nudged_candidates) > len(capped):
        print(f"  note: capped at --limit {args.limit}; "
              f"{len(nudged_candidates) - len(capped)} left for the next run")
    if blocked_not_behind:
        print(f"  note: {len(blocked_not_behind)} BLOCKED PR(s) missing a gate but "
              f"not behind base (update-branch can't re-trigger): "
              f"{', '.join('#' + str(n) for n in blocked_not_behind)}")

    nudged = 0
    for number, title, reason in capped:
        line = f"#{number} — {reason}"
        if not args.apply:
            print(f"  would nudge {line}")
            continue
        if _update_branch(repo, number):
            nudged += 1
            print(f"  nudged {line}")
    if args.apply:
        print(f"dropped-gate janitor: nudged {nudged}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
