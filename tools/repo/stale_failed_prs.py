"""Rebase prove-PRs whose Gate A failed *only because the branch fell stale*.

The swarm opens a `prove/<target>` PR for a proof that built locally, then moves
on. If that PR is not merged quickly, `main` races ahead — thousands of commits a
day — and, crucially, proofs that were live `library/Unsorry/*.lean` modules when
the branch was cut get *sealed into archive packages* on `main` (the draining
described in ADR-041 / ADR-048). When Gate A later builds `UnsorryLibrary --wfail`
on the stale branch, it rebuilds those long-since-archived modules in their *old*
state — and one of them trips a `--wfail` bar that `main` has since fixed. The
PR's own proof is fine; it fails on library state that no longer exists on `main`.
(Seen 2026-06-22: 22 valid `prove/*` PRs ~6,300 commits behind, all green again
after a single `update-branch`.)

This is the inverse of the dropped-gate janitor (tools/repo/dropped_gate_prs.py):
there the required gate is *absent*; here it is *present and failed*. So that
janitor deliberately leaves these alone ("a present gate failed → a real block").
This one rescues exactly the stale-failure case and nothing else.

  detect: PR open + not draft + head branch under --branch-prefix (default
          `prove/`) + latest gate-a run is terminal-non-pass (failed / timed-out
          / cancelled) + branch behind base by >= --min-behind + past a grace
          window + not DIRTY (a conflict can't be auto-rebased).

`--min-behind` is the load-bearing guard. It is both the *staleness signal* (only
far-behind branches hit the archived-module pathology) and the *loop guard*: an
`update-branch` resets the branch to ~0 behind, so a just-rebased PR cannot
re-qualify until `main` drifts >= --min-behind ahead again (hours later, by which
point Gate A has long since re-run and auto-merge has fired if it went green). A
proof that still fails while *current* (< --min-behind behind) is therefore
treated as a REAL failure and left untouched — this janitor never masks a genuine
proof error, and the worst case for a truly-broken stale PR is one bounded retest
every few hours, not a tight loop.

Like the dropped-gate janitor, the branch update must NOT use the default
GITHUB_TOKEN: events it triggers do not start new workflow runs, so Gate A would
never re-dispatch. Run with an admin PAT / App token (REFRESH_TOKEN) as GH_TOKEN
so the synchronize event is attributed to a real actor and Gate A actually runs.
Without it the job degrades to report-only.

Usage:
  python3 -m tools.repo.stale_failed_prs            # dry-run: list what would rebase
  python3 -m tools.repo.stale_failed_prs --apply    # update-branch (bounded)
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone

# Terminal, non-success states for the required gate: it ran and did not pass.
# A stale branch's old library trips --wfail here; that is the signal we rescue.
TERMINAL_NONPASS = frozenset(
    {"failure", "timed_out", "startup_failure", "cancelled"}
)

DEFAULT_GATE = "gate-a"
DEFAULT_BRANCH_PREFIX = "prove/"


def normalize_run_state(status: str | None, conclusion: str | None) -> str:
    """A check-run's status+conclusion → one normalized token.

    In-flight runs (status != completed) normalize to their status; completed
    runs normalize to their conclusion. Pure.
    """
    if (status or "") != "completed":
        return (status or "pending").lower()
    return (conclusion or "neutral").lower()


def latest_gate_state(gate: str, runs) -> str | None:
    """Most-recent normalized state of `gate` among `runs`, or None if absent.

    `runs` is an iterable of dicts with name/status/conclusion (+ optional
    started_at to pick the latest when the gate has several runs). Pure.
    """
    latest: tuple[str, str] | None = None  # (started_at, state)
    for r in runs:
        if r.get("name") != gate:
            continue
        started = r.get("started_at") or ""
        state = normalize_run_state(r.get("status"), r.get("conclusion"))
        if latest is None or started >= latest[0]:
            latest = (started, state)
    return None if latest is None else latest[1]


def stale_failed_reason(gate, gate_state, head_ref, branch_prefix, merge_state,
                        is_draft, behind_by, min_behind, age_minutes,
                        min_age_minutes) -> str | None:
    """Pure: is this PR a stale-failure we should rebase? Returns a human reason
    string when it is, else None. See the module docstring for each guard.

    `gate_state` is the latest normalized state of the required gate, or None if
    it has no run on the head SHA (that is the dropped-gate janitor's job, not
    ours, so we skip it).
    """
    if is_draft:
        return None
    if not head_ref.startswith(branch_prefix):
        return None                                   # not a swarm prove-PR
    if merge_state == "DIRTY":
        return None                                   # conflict — rebase can't fix
    if gate_state not in TERMINAL_NONPASS:
        return None                                   # only act on a FAILED gate
    if age_minutes < min_age_minutes:
        return None                                   # let the failure settle
    if behind_by < min_behind:
        return None                                   # current → real failure / loop guard
    return (f"prove-PR {behind_by} commits behind base with {gate} "
            f"'{gate_state}' — rebasing to retest on current main")


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
            "number,title,headRefName,headRefOid,isDraft,mergeStateStatus,updatedAt"]
    if repo:
        args += ["--repo", repo]
    return _gh_json(args, []) or []


def _gate_state(repo: str, sha: str, gate: str) -> str | None:
    # One bounded fetch (a head SHA carries well under 100 check-runs); the array
    # `--jq` yields a single JSON array so it parses cleanly.
    arr = _gh_json(["api", f"repos/{repo}/commits/{sha}/check-runs?per_page=100",
                    "--jq", "[.check_runs[] | {name,status,conclusion,started_at}]"], [])
    return latest_gate_state(gate, arr or [])


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
        prog="python3 -m tools.repo.stale_failed_prs",
        description="Rebase prove-PRs whose Gate A failed only because the branch fell stale.")
    ap.add_argument("--repo", default=None, help="owner/name (default: gh's repo)")
    ap.add_argument("--base", default="main", help="base branch (default: main)")
    ap.add_argument("--gate", default=DEFAULT_GATE,
                    help=f"required check to inspect (default: {DEFAULT_GATE})")
    ap.add_argument("--branch-prefix", default=DEFAULT_BRANCH_PREFIX,
                    help=f"only act on head branches under this prefix (default: {DEFAULT_BRANCH_PREFIX})")
    ap.add_argument("--apply", action="store_true", help="update-branch (default: dry-run)")
    ap.add_argument("--limit", type=int, default=20, help="max PRs to rebase per run")
    ap.add_argument("--min-behind", type=int, default=200,
                    help="only rebase branches at least this many commits behind base "
                         "(staleness signal + loop guard; default: 200)")
    ap.add_argument("--min-age-minutes", type=float, default=15.0,
                    help="ignore PRs whose last update is younger than this")
    args = ap.parse_args(argv)

    repo = args.repo
    if not repo:
        repo = (_gh_json(["repo", "view", "--json", "nameWithOwner"], {}) or {}).get(
            "nameWithOwner")
    if not repo:
        print("error: could not determine repo (pass --repo)", file=sys.stderr)
        return 1

    now = datetime.now(timezone.utc)

    candidates: list[tuple[int, str, str]] = []  # (number, title, reason)
    for pr in _open_prs(repo):
        if pr.get("isDraft"):
            continue
        head_ref = pr.get("headRefName", "")
        if not head_ref.startswith(args.branch_prefix):
            continue
        if pr.get("mergeStateStatus") == "DIRTY":
            continue
        sha = pr.get("headRefOid")
        if not sha:
            continue
        age = _age_minutes(pr.get("updatedAt", ""), now)
        if age < args.min_age_minutes:
            continue
        gate_state = _gate_state(repo, sha, args.gate)
        # Cheap pre-check before the (extra) compare call: only proceed on a
        # failed gate.
        if gate_state not in TERMINAL_NONPASS:
            continue
        behind = _behind_by(repo, args.base, sha)
        reason = stale_failed_reason(
            args.gate, gate_state, head_ref, args.branch_prefix,
            pr.get("mergeStateStatus", ""), False, behind, args.min_behind,
            age, args.min_age_minutes)
        if reason is None:
            continue
        candidates.append((int(pr["number"]), pr.get("title", ""), reason))

    capped = candidates[: args.limit]
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"stale-failed janitor: {len(candidates)} stale-failed prove-PR(s), "
          f"acting on {len(capped)} ({mode})")
    if len(candidates) > len(capped):
        print(f"  note: capped at --limit {args.limit}; "
              f"{len(candidates) - len(capped)} left for the next run")

    rebased = 0
    for number, _title, reason in capped:
        line = f"#{number} — {reason}"
        if not args.apply:
            print(f"  would rebase {line}")
            continue
        if _update_branch(repo, number):
            rebased += 1
            print(f"  rebased {line}")
    if args.apply:
        print(f"stale-failed janitor: rebased {rebased}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
