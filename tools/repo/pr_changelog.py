"""Changelog-fragment advisory (ADR-040).

ADR-040 records user-facing changes as one `changelog.d/<category>-<slug>.md`
file per change, so concurrent PRs never collide on the changelog. The rule is a
convention (CONTRIBUTING.md): *every user-facing change ships a fragment; a
single swarm proof does not.* Nothing enforced it, so contributors forget and a
maintainer backfills by hand (issue #445).

This module is the gentle reminder. It is **advisory, not a gate** — it never
exits non-zero and never blocks a PR — because the line between "user-facing"
and "internal" is a judgement call the author owns (plenty of legitimate harness
fixes ship no fragment). It exists to catch the *obvious* miss, not to police.

It reuses the two existing classifiers so the rules live in one place:

  * `pr_scope.surface` (ADR-027) tells the proof surface from the harness
    surface. Only a **harness** change can ever warrant a fragment, which makes
    the advisory swarm-safe by construction: a proof PR touches no harness path,
    so it can never fire — and proof PRs are ~98% of all traffic.
  * `pr_labels.classify` (ADR-026) maps the title to its kind. Only the
    user-facing conventional types below are considered; swarm / release /
    metrics / docs / test shapes are intentionally exempt.

Usage (mirrors pr_scope):
  gh pr view <n> --json files --jq '.files[].path' \
    | python3 -m tools.repo.pr_changelog check "<pr title>"
"""
from __future__ import annotations

import sys

from tools.repo import pr_labels, pr_scope

#: Conventional-commit kinds whose *harness* changes are usually user-facing and
#: so warrant a changelog fragment (Keep a Changelog). `test` (never user-facing)
#: and `docs` (tracked separately; rarely a harness change) are excluded, as are
#: all swarm / release / metrics / red-team shapes. This is the one policy knob —
#: widen or narrow it to tune how often the advisory speaks.
USER_FACING_TYPES = frozenset({"feat", "fix", "perf", "ci", "build", "refactor", "chore"})

_FRAGMENT_PREFIX = "changelog.d/"
_FRAGMENT_README = "changelog.d/README.md"


def _is_user_facing(title: str) -> bool:
    """True iff the title's kind is one that normally carries a fragment.

    `pr_labels.classify` returns the bare conventional type (`fix`, `feat`, …)
    for non-doc conventional titles, and a namespaced label (`swarm:prove`,
    `release`, `docs`, `metrics`, `red-team`) for everything else — so a plain
    membership test against `USER_FACING_TYPES` exempts the swarm automatically.
    """
    return any(label in USER_FACING_TYPES for label in pr_labels.classify(title))


def _touches_harness(paths: list[str]) -> bool:
    """True iff any changed path is on the trust-bearing harness surface."""
    return any(pr_scope.surface(p) == "harness" for p in paths if p.strip())


def has_fragment(paths: list[str]) -> bool:
    """True iff the changed set adds a changelog fragment.

    A fragment is any `changelog.d/*.md` other than the directory's README, which
    is documentation rather than a release note.
    """
    for p in paths:
        p = p.strip()
        if p.startswith(_FRAGMENT_PREFIX) and p.endswith(".md") and p != _FRAGMENT_README:
            return True
    return False


def needs_fragment(title: str, paths: list[str]) -> bool:
    """True iff this PR is a user-facing harness change with no fragment."""
    return _is_user_facing(title) and _touches_harness(paths) and not has_fragment(paths)


def check(title: str, paths: list[str]) -> list[str]:
    """Advisory messages for a PR — empty when exempt or already satisfied."""
    if not needs_fragment(title, paths):
        return []
    return [
        "This looks like a user-facing harness change with no changelog fragment "
        "(ADR-040). If it is user-facing, add one bullet at "
        "changelog.d/<category>-<slug>.md (category: added/changed/deprecated/"
        "removed/fixed/security; slug unique — include the PR or issue number). "
        "If the change is purely internal, no fragment is needed and you can "
        "ignore this. See changelog.d/README.md. (Advisory only — not a gate.)"
    ]


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 2 or argv[0] != "check":
        print(
            "usage: pr_changelog.py check '<pr title>'   # paths read from stdin",
            file=sys.stderr,
        )
        return 2
    title = argv[1]
    paths = [line for line in sys.stdin.read().splitlines() if line.strip()]
    for msg in check(title, paths):
        print(msg)
    # Advisory: always succeed. Even if wired as a required check it can never
    # block a merge — the workflow surfaces the message as a warning instead.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
