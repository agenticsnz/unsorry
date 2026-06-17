# SPEC-061-A: Unique ADR/SPEC Numbering Gate

Implements: [ADR-061](../ADR-061-Unique-ADR-Numbering-Gate.md) · Status: Living · Updated: 2026-06-17

## Where it lives

`tools/repo/pr_protocol.check(added, existing)` (the ADR-028 gate) gains a second
rule alongside spec-linkage. Same inputs: `added` = the PR's added paths (from
`gh api .../pulls/<n>/files`, `status=="added"`), `existing` = the base-ref
`docs/adrs/**/*.md` tree (`_scan_tree`). No change to `.github/workflows/pr-protocol.yml`'s
invocation — only its name/comment widen to say it also enforces uniqueness.

## Uniqueness keys

- **ADR:** key = the number. `docs/adrs/ADR-(\d+)-*.md` → `<n>`.
- **SPEC:** key = number **and** letter. `docs/adrs/specs/SPEC-(\d+)-([A-Za-z])-*.md`
  → `<n>-<LETTER>` (uppercased). So `SPEC-003-A` and `SPEC-003-B` are distinct
  keys (multiple spec parts per ADR are legal); two `SPEC-003-A-*` files collide.

## Rule

Over the pool (`existing ∪ added`), group file paths by key. For every key an
**added** file participates in, if that key maps to **more than one distinct
path**, emit a violation naming the colliding paths:

- `ADR-<n> number is reused by multiple files: <p1>, <p2>`
- `SPEC-<n>-<L> number is reused by multiple files: <p1>, <p2>`

Only keys an added file touches are flagged — a pre-existing duplicate on the
base tree never blocks an unrelated PR (mirrors ADR-028's added-only scope).
`main()` exits 1 with the combined linkage+uniqueness violations, 0 otherwise.

## Acceptance criteria

`tools/repo/tests/test_pr_protocol.py` (pure, no I/O):

1. added `ADR-059-Bar` + existing `ADR-059-Foo` → flagged, message names both;
2. two added ADRs sharing a number → flagged;
3. a fresh unique number (added `ADR-200` over an existing `ADR-059`) → passes;
4. added `SPEC-003-B` when `SPEC-003-A` exists → passes (legal new letter);
5. added `SPEC-003-A` when `SPEC-003-A` already exists → flagged;
6. a pre-existing base-tree duplicate, PR touches neither → passes;
7. all six original ADR-028 linkage tests still pass.

Incident record: the ADR-059 collision (#1757 + #1837 → renumber #1884) is the
motivating failure; post-gate, a PR reusing an ADR/SPEC number fails the
required `pr-protocol` check.
