# ADR-061: Unique ADR/SPEC Numbering Gate

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-061 |
| **Initiative** | unsorry — protocol-compliance hardening |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Accepted |

## Context

ADR numbers are the stable handles the whole repo cites — code comments, specs,
changelog fragments, CONTRIBUTING, dependency tables. They are assumed unique.
Nothing enforced that. On 2026-06-17 two PRs (#1757 and #1837) independently
chose **ADR-059** and merged ~40 seconds apart, leaving `main` with two
`ADR-059-*.md` files (and two `SPEC-059-A-*.md`); a follow-up PR (#1884) had to
renumber one to ADR-060 and fix every reference.

The existing protocol gate (ADR-028, `tools/repo/pr_protocol.py`) already runs
per-PR over the *added* decision records and verifies each added ADR has a
matching spec. It is the natural place to also assert that an added record does
not reuse a number already taken — it is checked out on the base ref, so it can
see the base `docs/adrs/` tree and compare the PR's additions against it.

## WH(Y) Decision Statement

**In the context of** ADR numbers being load-bearing identifiers assumed unique
across the repo, with a per-PR protocol gate (ADR-028) already scanning added
ADR/spec files against the base tree,
**facing** the #1757/#1837 incident in which two PRs claimed ADR-059 and both
merged, producing duplicate ADR-059/SPEC-059-A files on `main` and a manual
renumber (#1884),
**we decided for** extending the ADR-028 gate so an added `ADR-<n>` that
collides with a different ADR file of the same number — or an added
`SPEC-<n>-<letter>` colliding with the same number+letter — fails the gate, with
the collision keyed so multiple spec letters per number (SPEC-003-A/B/C) stay
legal, and only keys an added file participates in are flagged (a pre-existing
duplicate never blocks an unrelated PR, mirroring ADR-028's added-only scope),
**and neglected** a standalone post-merge job that scans `main` for duplicates
(rejected — surfaces the clash only after it has already landed; the per-PR gate
prevents it at the door for the common case where the colliding number is
already on the base), and renumber-by-letter or hash-based ADR ids (rejected —
sequential human-readable numbers are the established convention and the cited
handle; the fix is to guard them, not replace them),
**to achieve** a tree where an ADR/SPEC number reused by a PR is caught by a
required check instead of by a maintainer noticing duplicate files days later,
**accepting that** two PRs that both branch from a number-free base and merge
with non-strict (not-up-to-date) checks can still both land — closing that last
window needs branch-protection "require branches up to date" (out of scope
here); the gate still catches every PR opened or re-evaluated against a base
that already carries the number, which is the overwhelmingly common case.

## Options Considered

### Option 1: Extend the ADR-028 per-PR gate with a uniqueness check (Selected)
**Pros:** reuses the existing gate, its base-ref checkout, and its added-files
input — no new workflow; pure-function check, hermetically testable; fails at the
door for the common case.
**Cons:** cannot catch two PRs that both branch from a number-free base and merge
with stale non-strict checks (needs "require up-to-date").

### Option 2: Standalone post-merge duplicate scan on `main` (Rejected)
A job that scans `main` and opens an issue on a duplicate. Rejected: detects the
clash only after it lands; the per-PR gate is preventive.

### Option 3: Replace sequential numbers with hashes/letters (Rejected)
Make collisions structurally impossible by changing the id scheme. Rejected:
sequential numbers are the established, cited convention; guard them instead.

## Consequences

- `tools/repo/pr_protocol.check()` gains the uniqueness rule; the `pr-protocol`
  workflow (ADR-028) now enforces spec-linkage **and** number uniqueness with no
  change to how it is invoked.
- A PR reusing an ADR/SPEC number fails a required check with a message naming
  the colliding files; the fix is to pick the next free number.
- Multiple spec letters per ADR number remain legal (keyed by number+letter).

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Amends | ADR-028 | Protocol Compliance Gate | Adds a number-uniqueness rule to the same per-PR gate |
| Relates To | ADR-019 | CI Supply-Chain Protection | The gate is a trust-bearing surface; this change rides a code-owner review |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-061-A — Unique ADR/SPEC numbering gate | Specification | specs/SPEC-061-A-Unique-ADR-Numbering-Gate.md |
| REF-2 | The ADR-059 collision and its renumber | Incident | PRs #1757, #1837, #1884 |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
| Accepted | unsorry maintainers | 2026-06-17 |
