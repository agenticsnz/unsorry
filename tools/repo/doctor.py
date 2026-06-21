"""Operator preflight doctor (ADR-065, a first slice of ADR-051/ADR-056).

Runs cheap, side-effect-free health checks and reports OK/WARN/FAIL so a
misconfiguration is caught *before* it silently breaks autonomous operation,
instead of surfacing as a cryptic mid-run error.

The flagship check is ``pr-token``: it verifies the active token can actually
open pull requests. This catches the failure mode where the scheduled
queue-dispatcher's ``REFRESH_TOKEN`` lacks pull-request-write permission and so
creates zero PRs every run while erroring with
``Resource not accessible by personal access token (createPullRequest)``.

The check is a *probe*, not a mutation: it POSTs to the pulls endpoint with no
``head``/``base``, so GitHub rejects it during validation (HTTP 422) and never
creates a PR — but only *after* it has authorized the token, so an unauthorized
token returns HTTP 403 first. The HTTP status therefore distinguishes
"authorized but invalid request" (422 → OK) from "not authorized" (403 → FAIL)
without any side effect.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import os
import re
import subprocess
import sys

OK = "OK"
WARN = "WARN"
FAIL = "FAIL"


@dataclass
class Check:
    name: str
    level: str
    detail: str


def classify_pr_permission(status: int, message: str) -> Check:
    """Map the HTTP status of the no-op PR-create probe to a Check (pure).

    422 means GitHub reached request validation, so the token *is* authorized to
    create PRs. 401/403/404 mean it is not (bad token / missing PR-write / no
    repo access). Anything else is inconclusive.
    """
    if status == 422:
        return Check("pr-token", OK,
                     "token can open pull requests (authorization reached request validation)")
    if status == 401:
        return Check("pr-token", FAIL, "token is invalid or expired (HTTP 401)")
    if status == 403:
        return Check("pr-token", FAIL,
                     "token cannot open pull requests (HTTP 403) — grant 'Pull requests: write' "
                     "(fine-grained PAT) or 'repo' scope (classic PAT) to the token used here")
    if status == 404:
        return Check("pr-token", FAIL,
                     "token cannot access the repository (HTTP 404) — no access, or wrong --repo")
    if status == 0:
        return Check("pr-token", WARN,
                     "PR-create probe unexpectedly succeeded — verify no stray PR was opened")
    return Check("pr-token", WARN,
                 f"could not determine PR-create permission (HTTP {status}): {message[:200]}")


def parse_http_status(returncode: int, output: str) -> int:
    """Extract the HTTP status from gh output. gh formats API errors as
    ``... (HTTP 403)``; a clean exit with no marker means success (0)."""
    match = re.search(r"\(HTTP (\d+)\)", output)
    if match:
        return int(match.group(1))
    return 0 if returncode == 0 else -1


def _probe_pr_create(repo: str) -> tuple[int, str]:
    """POST to the pulls endpoint with no head/base (no PR can be created).
    Uses the ambient gh auth / GH_TOKEN. Returns (http_status, raw_output)."""
    proc = subprocess.run(
        ["gh", "api", "-X", "POST", f"repos/{repo}/pulls",
         "-f", "title=unsorry-doctor-preflight"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False,
    )
    output = (proc.stdout or "").strip()
    return parse_http_status(proc.returncode, output), output


def check_pr_token(repo: str) -> Check:
    status, output = _probe_pr_create(repo)
    return classify_pr_permission(status, output)


# Registry of checks. Each entry: (name, callable(repo) -> Check). New operator
# checks (runner capacity, last dispatcher run, ...) slot in here (ADR-051/056).
CHECKS = {
    "pr-token": check_pr_token,
}

ICON = {OK: "✓", WARN: "!", FAIL: "✗"}


def _default_repo() -> str | None:
    return os.environ.get("GITHUB_REPOSITORY") or None


def run_checks(names: list[str], repo: str) -> list[Check]:
    return [CHECKS[name](repo) for name in names]


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.repo.doctor",
        description="Operator preflight health checks (ADR-065).")
    parser.add_argument("--repo", default=_default_repo(),
                        help="owner/name (default: $GITHUB_REPOSITORY)")
    parser.add_argument("--check", action="append", choices=sorted(CHECKS),
                        help="run only this check (repeatable; default: all)")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if not args.repo:
        print("doctor: --repo is required (or set $GITHUB_REPOSITORY)", file=sys.stderr)
        return 2
    names = args.check or sorted(CHECKS)
    results = run_checks(names, args.repo)
    if args.json:
        import json
        print(json.dumps([r.__dict__ for r in results], indent=2))
    else:
        for r in results:
            print(f"{ICON.get(r.level, '?')} [{r.level}] {r.name}: {r.detail}")
    return 1 if any(r.level == FAIL for r in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
