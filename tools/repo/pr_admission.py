"""Repository-side PR admission policy for the queued proof cutover.

This is deliberately small and stdlib-only so trusted `pull_request_target`
workflows can run it from the base checkout before touching PR-head code.

Usage:
  python3 -m tools.repo.pr_admission check --created-at ... --head-ref ... --title ...
  python3 -m tools.repo.pr_admission env   --created-at ... --head-ref ... --title ...

The `check`/`env` subcommands additionally read $GITHUB_EVENT_PATH and
$GITHUB_REPOSITORY (trusted base-checkout context) to detect fork-native
cross-repo proof PRs (ADR-068) and exempt them from the queued-proof cutover.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import json
import os
import sys


DEFAULT_CUTOVER = "2026-06-16T22:24:44Z"
# A direct proof submission is identified by its `prove(` TITLE or the dedicated
# `prove/` branch — NOT by the `feature/goal-` branch prefix. ADR-009 coordination
# PRs (unblock(...)/decompose(...)) legitimately live on `feature/goal-*` branches
# too, so matching that prefix auto-closed them and left parents permanently
# blocked (issue #3128). The `prove(` title is the reliable, unambiguous signal.
DIRECT_BRANCH_PREFIXES = ("prove/",)
QUEUE_BRANCH_PREFIX = "queued/prove/"
DIRECT_TITLE_PREFIXES = ("prove(",)

# Per-contributor fairness cap on simultaneous open prove PRs (ADR-054 quota
# layer). The shared open-PR budget (UNSORRY_MAX_OPEN_PROVE_PRS) is global, so
# without a per-author bound one fleet can fill it and pause submissions for
# everyone — the "CI flooding / credit gaming" ADR-054 names. Enforced only at
# submission time (opened/reopened), so a contributor's oldest PRs keep draining
# and only NEW over-cap submissions are turned away (FIFO fairness).
DEFAULT_MAX_OPEN_PROVE_PRS_PER_AUTHOR = 20


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


def decide(created_at: str, head_ref: str, title: str, cutover: str = DEFAULT_CUTOVER,
           is_fork: bool = False) -> Admission:
    """Return the admission verdict for a PR.

    Empty `created_at` means "not a PR event" (for example push-to-main), which
    remains admitted. Existing direct proof PRs created before the cutover keep
    draining. New direct proof submissions after the cutover must enter through
    `queued/prove/*`, which is what the dispatcher opens.

    `is_fork` marks a fork-native cross-repo PR (ADR-068): the supported
    non-contributor onramp. A fork has no write access to the upstream-only
    `queued/prove/*` namespace and cannot run the dispatcher, so it submits a
    direct cross-repo PR by necessity, not to skip the metered queue. Such a PR
    is legitimately direct and is exempted from the queued-proof cutover block.
    Soundness is unaffected — admission is a routing/fairness policy, not a
    soundness gate; Gate A still re-verifies the proof from scratch on upstream
    runners (ADR-052/ADR-068). `is_fork` MUST be derived only from trusted
    base-checkout context (see resolve_is_fork), never from head-controlled
    branch/title, so a same-repo PR cannot spoof it to bypass the cutover.

    The per-author open-PR quota (quota_decide) remains in force wherever the
    workflow enforces it. NOTE/FLAG (separate pre-existing gap, intentionally not
    fixed here): pr-admission.yml only runs the quota step for branches matching
    `queued/prove/*`, and quota_decide is counted over that same prefix. Fork
    branches are `prove/*` or `feature/goal-*` (the upstream-only
    `queued/prove/*` namespace is inaccessible to forks — the premise of this
    exemption), so the workflow's quota step is currently SKIPPED for fork PRs.
    quota_decide itself is unchanged and would apply if invoked; broadening the
    workflow's quota count/gate to also meter fork-native proof PRs is an
    ADR-054 follow-up, out of scope for this change.
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
    if is_fork:
        return Admission(
            True,
            "fork-native cross-repo proof PR admitted past the queued cutover: the "
            "queued/prove/* path is upstream-only and inaccessible to forks, so this "
            "direct PR is the supported fork onramp (ADR-068); Gate A still "
            "re-verifies the proof (ADR-058)",
        )
    return Admission(
        False,
        "direct proof PRs after the queued-proof cutover must be submitted via queued/prove/*",
    )


def resolve_is_fork(event_path: str | None = None, repository: str | None = None) -> bool:
    """Determine whether the current PR is a fork-native cross-repo PR (ADR-068).

    Reads ONLY trusted, base-checkout context: the GitHub event payload at
    $GITHUB_EVENT_PATH (`pull_request.head.repo.full_name`) compared against
    $GITHUB_REPOSITORY (the base repo). This is the trust boundary required by
    ADR-068 — neither field is settable by head-controlled data (branch name or
    PR title), so a same-repo PR cannot spoof fork status to skip the cutover.

    Returns True only when both repo names are present and differ. Any
    missing/null field, unreadable or malformed event JSON, or absent repository
    yields False (fail-closed: treat as same-repo, keep the cutover block).
    """
    event_path = event_path if event_path is not None else os.environ.get("GITHUB_EVENT_PATH", "")
    repository = repository if repository is not None else os.environ.get("GITHUB_REPOSITORY", "")
    repository = (repository or "").strip()
    if not event_path or not repository:
        return False
    try:
        with open(event_path, encoding="utf-8") as handle:
            event = json.load(handle)
    except (OSError, ValueError):
        return False
    node: object = event
    for key in ("pull_request", "head", "repo", "full_name"):
        if not isinstance(node, dict):
            return False
        node = node.get(key)
    if not isinstance(node, str) or not node.strip():
        return False
    return node.strip() != repository


def quota_decide(open_prove_count: int,
                 cap: int = DEFAULT_MAX_OPEN_PROVE_PRS_PER_AUTHOR) -> Admission:
    """Verdict for the per-contributor open-prove-PR fairness cap (ADR-054).

    `open_prove_count` is the author's number of open `queued/prove/*` PRs,
    counting the one under evaluation. At or under the cap → admitted; over it →
    not admitted, so the author settles at exactly `cap` open prove PRs and the
    rest of the shared budget stays available to other contributors.
    """
    if open_prove_count <= cap:
        return Admission(
            True, f"within per-contributor open-PR cap ({open_prove_count}/{cap})")
    return Admission(
        False,
        f"author has {open_prove_count} open prove PRs, over the per-contributor "
        f"cap of {cap} — newest over-cap submission turned away (ADR-054)")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("check", "env", "explain", "quota"))
    parser.add_argument("--created-at", default="")
    parser.add_argument("--head-ref", default="")
    parser.add_argument("--title", default="")
    parser.add_argument("--cutover", default=DEFAULT_CUTOVER)
    parser.add_argument("--open-count", type=int, default=0)
    parser.add_argument("--cap", type=int,
                        default=DEFAULT_MAX_OPEN_PROVE_PRS_PER_AUTHOR)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(sys.argv[1:] if argv is None else argv)
    if args.command == "quota":
        verdict = quota_decide(args.open_count, args.cap)
        print(f"admitted={'true' if verdict.admitted else 'false'}")
        print(f"reason={verdict.reason}")
        return 0
    # is_fork is resolved ONLY from trusted base-checkout context
    # ($GITHUB_EVENT_PATH / $GITHUB_REPOSITORY), never from the head-controlled
    # --head-ref/--title args, so a same-repo PR cannot spoof it (ADR-068).
    is_fork = resolve_is_fork()
    verdict = decide(args.created_at, args.head_ref, args.title, args.cutover, is_fork)
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
