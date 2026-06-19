# ADR-073: Generated ADR Index (README + JSON), Refreshed Post-Merge

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-073 |
| **Initiative** | unsorry — decision-record discoverability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-18 |
| **Status** | Accepted |

## Context

`docs/adrs/` holds 70+ ADRs but has **no index**: to see what decisions exist and
their status you must open files one at a time. Every ADR already carries a uniform
header table (`# ADR-NNN: Title` H1, a `**Status**` row, a `**Date**` row), so a
table of all ADRs and their status is mechanically derivable — there is no reason to
maintain it by hand, and a hand-maintained one would silently drift the moment an ADR
is added or its status changes.

The repository already has a consistent model for this class of artifact. The
leaderboard (ADR-023), proof-graph / proofs visualisation (ADR-032), targets board
(ADR-036), and queue board (ADR-066) are all **generated** from repo state by a tool
under `tools/` and kept fresh by a workflow, not edited by humans. ADR-036 in
particular established *why* such a board must be refreshed **post-merge** rather than
in each PR: a whole-corpus artifact changes on every contributing PR, so regenerating
it in-PR makes any two concurrent PRs conflict on the file. An index of *all* ADRs has
exactly that property — every ADR PR would touch it.

## WH(Y) Decision Statement

**In the context of** a growing `docs/adrs/` directory with no at-a-glance index of
which decisions exist and what their status is,
**facing** the choice between a hand-maintained index (drifts the moment an ADR is
added or re-statused, and an in-PR freshness gate would make concurrent ADR PRs
conflict on the shared file — the ADR-036 churn) and no index at all,
**we decided for** a generated index: a `tools.adr_index` generator that parses the
`docs/adrs/ADR-*.md` headers and writes two artifacts into the same directory —
`docs/adrs/README.md` (a human-readable **ADR · Title · Status · Date** table) and
`docs/adrs/adrs.json` (the same data, structured for machines) — refreshed
**post-merge** by an `adr-index.yml` workflow that, on every push to `main` touching
ADR state, runs `--check` and on drift regenerates and commits both files back to
`main` as a single docs-only `[skip ci]` commit (mirroring `targets-board.yml`),
**and neglected** a hand-maintained index (drift), an in-PR regen + gate-b `--check`
(the ADR-036 conflict, reintroduced), and a Markdown-only output with no machine
companion (downstream tooling would have to re-parse the ADR corpus),
**to achieve** an always-accurate, zero-maintenance index that both humans and tools
can consume, with ADR PRs that never conflict on it,
**accepting that** the index on `main` is briefly stale between a merge and the
refresh run (acceptable — it is a derived convenience view; the `ADR-*.md` files
remain authoritative), that the refresh requires the `REFRESH_TOKEN` admin secret to
push to protected `main` (the same requirement ADR-036 / #417 already carry; without
it the workflow degrades to a report-only warning), and that the generator emits a
non-fatal warning for duplicate ADR numbers (the corpus currently has two `ADR-041`s)
rather than failing — surfacing the collision without blocking the index.

## Consequences

- **Positive.** A reliable, self-updating ADR table + JSON; ADR PRs never conflict on
  the index; the index joins the one consistent post-merge generated-artifact model
  (ADR-023 / ADR-032 / ADR-036 / ADR-066); duplicate ADR numbers become visible.
- **Negative.** A brief window where `main`'s index lags a just-merged ADR change
  (bounded by the workflow run); dependence on the `REFRESH_TOKEN` push-to-`main`
  secret; `docs/adrs/README.md` and `docs/adrs/adrs.json` are generated and must not
  be hand-edited (a banner in the README says so).
- The `adr-index.yml` workflow lives under `.github/`, owned by `@cgbarlow`
  (ADR-019 / CODEOWNERS), so this change requires a code-owner review.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | ADR-index generator + workflow spec | Specification | specs/SPEC-073-A-ADR-Index.md |
| REF-2 | The post-merge generated-artifact pattern this mirrors | Decision | ADR-036-Targets-Board-Post-Merge-Refresh.md |
| REF-3 | Generated-board precedents | Decision | ADR-023-Proof-Provenance-Leaderboard.md / ADR-066 (queue board) |
| REF-4 | Adopt Development Protocols (ADR/spec/WH(Y) process) | Decision | ADR-001-Adopt-Development-Protocols.md |
| REF-5 | CI supply-chain protection (owned `.github/`, pinned actions) | Decision | ADR-019-CI-Supply-Chain-Protection.md |
| REF-6 | Refresh-token push-to-`main` requirement | Issue | https://github.com/agenticsnz/unsorry/issues/417 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-18 |
| Accepted | unsorry maintainers | 2026-06-18 |
