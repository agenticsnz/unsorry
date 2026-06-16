"""Repository-side PR admission policy for the queued proof cutover.

This is deliberately small and stdlib-only so trusted `pull_request_target`
workflows can run it from the base checkout before touching PR-head code.

Usage:
  python3 -m tools.repo.pr_admission check --created-at ... --head-ref ... --title ...
  python3 -m tools.repo.pr_admission env   --created-at ... --head-ref ... --title ...
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import sys


DEFAULT_CUTOVER = "2026-06-16T22:24:44Z"
DIRECT_BRANCH_PREFIXES = ("feature/goal-", "prove/")
QUEUE_BRANCH_PREFIX = "queued/prove/"
DIRECT_TITLE_PREFIXES = ("prove(",)


@dataclass(frozen=True)
class Admission:
    admitted: bool
    reason: str


def _parse_instant(value: str) -> datetime:
    normalized = value.strip().replace("Z", "+00:00")
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _direct_submission(head_ref: str, title: str) -> bool:
    if head_ref.startswith(QUEUE_BRANCH_PREFIX):
        return False
    return head_ref.startswith(DIRECT_BRANCH_PREFIXES) or title.startswith(DIRECT_TITLE_PREFIXES)


def decide(created_at: str, head_ref: str, title: str, cutover: str = DEFAULT_CUTOVER) -> Admission:
    """Return the admission verdict for a PR.

    Empty `created_at` means "not a PR event" (for example push-to-main), which
    remains admitted. Existing direct proof PRs created before the cutover keep
    draining. New direct proof submissions after the cutover must enter through
    `queued/prove/*`, which is what the dispatcher opens.
    """
    created_at = created_at.strip()
    head_ref = head_ref.strip()
    title = title.strip()
    if not created_at:
        return Admission(True, "not a pull request event")
    if not _direct_submission(head_ref, title):
        return Admission(True, "not a direct proof submission")
    created = _parse_instant(created_at)
    threshold = _parse_instant(cutover)
    if created < threshold:
        return Admission(True, "direct proof PR predates the queued-proof cutover")
    return Admission(
        False,
        "direct proof PRs after the queued-proof cutover must be submitted via queued/prove/*",
    )


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("check", "env", "explain"))
    parser.add_argument("--created-at", default="")
    parser.add_argument("--head-ref", default="")
    parser.add_argument("--title", default="")
    parser.add_argument("--cutover", default=DEFAULT_CUTOVER)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(sys.argv[1:] if argv is None else argv)
    verdict = decide(args.created_at, args.head_ref, args.title, args.cutover)
    if args.command == "env":
        print(f"admitted={'true' if verdict.admitted else 'false'}")
        print(f"reason={verdict.reason}")
        return 0
    if args.command == "explain":
        print(verdict.reason)
        return 0
    if verdict.admitted:
        print(verdict.reason)
        return 0
    print(verdict.reason, file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
