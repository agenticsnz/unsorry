"""Protocol-compliance gate (ADR-028, ADR-061): ADR/spec hygiene.

`docs/protocols.md` requires a spec per ADR and a unique number per decision.
This gate enforces both for *newly added* decision records only — historical
ADRs that predate the convention (or reuse another ADR's spec) are untouched:

1. **Spec linkage (ADR-028):** an added `ADR-<n>-*.md` must have a matching
   `SPEC-<n>-*.md` (added in the same PR or already present), and an added
   `SPEC-<n>` must have a matching `ADR-<n>`.
2. **Number uniqueness (ADR-061):** an added `ADR-<n>` must not collide with
   another ADR file of the same number, and an added `SPEC-<n>-<letter>` must
   not collide with another spec of the same number+letter (multiple letters
   per number, e.g. SPEC-003-A/B/C, stay legal). Two PRs that independently
   claim the same number and merge moments apart are how `main` ends up with
   duplicate ADR-<n> files; checked against the base tree, the second one to be
   (re)evaluated now fails here.

Usage:
  gh api .../pulls/<n>/files --jq '.[]|select(.status=="added")|.filename' \
    | python3 -m tools.repo.pr_protocol check
The added paths are read from stdin (or argv after `check`); existing ADRs/specs
are scanned from the working tree under docs/adrs/.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Callable

ADR_RE = re.compile(r"(?:^|/)docs/adrs/ADR-(\d+)-[^/]+\.md$")
SPEC_RE = re.compile(r"(?:^|/)docs/adrs/specs/SPEC-(\d+)-[^/]+\.md$")
# Uniqueness keys: an ADR is keyed by its number; a spec by number+letter, so
# SPEC-003-A and SPEC-003-B are distinct but two SPEC-003-A files collide.
ADR_KEY_RE = re.compile(r"(?:^|/)docs/adrs/ADR-(\d+)-[^/]+\.md$")
SPEC_KEY_RE = re.compile(r"(?:^|/)docs/adrs/specs/SPEC-(\d+)-([A-Za-z])-[^/]+\.md$")


def _numbers(paths: list[str], pattern: re.Pattern) -> set[str]:
    out: set[str] = set()
    for p in paths:
        m = pattern.search(p.strip())
        if m:
            out.add(m.group(1))
    return out


def _by_key(
    paths: list[str], pattern: re.Pattern, keyfn: Callable[[re.Match], str]
) -> dict[str, set[str]]:
    """Map each uniqueness key to the set of distinct file paths that carry it."""
    out: dict[str, set[str]] = {}
    for p in paths:
        p = p.strip()
        m = pattern.search(p)
        if m:
            out.setdefault(keyfn(m), set()).add(p)
    return out


def check(added: list[str], existing: list[str]) -> list[str]:
    """Violations for the added paths given everything present after the merge.

    `existing` should be the post-merge file set (base tree ∪ added), so a PR that
    adds both ADR-<n> and SPEC-<n> passes."""
    pool = list(existing) + list(added)
    have_adr = _numbers(pool, ADR_RE)
    have_spec = _numbers(pool, SPEC_RE)
    violations: list[str] = []
    # 1. Spec linkage (ADR-028).
    for n in sorted(_numbers(added, ADR_RE)):
        if n not in have_spec:
            violations.append(f"ADR-{n} added without a matching docs/adrs/specs/SPEC-{n}-*.md")
    for n in sorted(_numbers(added, SPEC_RE)):
        if n not in have_adr:
            violations.append(f"SPEC-{n} added without a matching docs/adrs/ADR-{n}-*.md")
    # 2. Number uniqueness (ADR-061): an added record may not reuse a number
    # already taken by a different file. Only keys an added file participates in
    # are flagged, so a pre-existing duplicate never blocks an unrelated PR.
    adr_by_num = _by_key(pool, ADR_KEY_RE, lambda m: m.group(1))
    for key in sorted(_by_key(added, ADR_KEY_RE, lambda m: m.group(1))):
        paths = adr_by_num.get(key, set())
        if len(paths) > 1:
            violations.append(
                f"ADR-{key} number is reused by multiple files: " + ", ".join(sorted(paths))
            )
    spec_by_key = _by_key(pool, SPEC_KEY_RE, lambda m: f"{m.group(1)}-{m.group(2).upper()}")
    for key in sorted(_by_key(added, SPEC_KEY_RE, lambda m: f"{m.group(1)}-{m.group(2).upper()}")):
        paths = spec_by_key.get(key, set())
        if len(paths) > 1:
            violations.append(
                f"SPEC-{key} number is reused by multiple files: " + ", ".join(sorted(paths))
            )
    return violations


def _scan_tree(root: Path) -> list[str]:
    adrs = root / "docs" / "adrs"
    if not adrs.is_dir():
        return []
    return [str(p.relative_to(root)) for p in adrs.rglob("*.md")]


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if not argv or argv[0] != "check":
        print("usage: pr_protocol.py check [added_path ...]   # added also read from stdin", file=sys.stderr)
        return 2
    added = argv[1:] or [line for line in sys.stdin.read().splitlines() if line.strip()]
    violations = check(added, _scan_tree(Path.cwd()))
    if not violations:
        return 0
    print(
        "Protocol violation (ADR-028 / ADR-061) — every implementation ADR needs a "
        "spec, and each ADR/SPEC number must be unique:\n  "
        + "\n  ".join(violations)
        + "\nAdd the matching ADR/spec, or pick the next free number (see docs/protocols.md).",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
