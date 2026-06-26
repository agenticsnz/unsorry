# ADR-077: Roadmap GitHub Project, Synced from Repo State

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-077 |
| **Initiative** | unsorry — decision & work roadmap discoverability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-20 |
| **Status** | Proposed |

## Context

The project's planning state is spread across two artifacts with no single at-a-glance
roadmap. ADRs (`docs/adrs/`, indexed by ADR-073 into `adrs.json`) record *decisions* and
carry a status — `Proposed` (still pending) or `Accepted` — but you only see the pending
work-ahead by reading the index. Repo *issues* track in-flight work but live in a
separate list. There is no view that answers "what is on the roadmap, and what's pending
vs done" across both.

A GitHub Project (Projects v2) is the natural home for that view, and it already
mirrors *linked issues* live (an issue's open/closed state, title, and labels update on
the board automatically). But it has **no native notion of "files as items"**: an ADR is
a Markdown file, so a new ADR — or a `Proposed` → `Accepted` flip in `adrs.json` — never
reaches the board on its own. A hand-maintained board would silently drift the moment an
ADR is added or re-statused, exactly as a hand-maintained ADR index would (the problem
ADR-073 solved by generating it).

The repository already has one consistent model for this: derive the artifact from repo
state with a tool under `tools/`, and keep it fresh with a workflow (leaderboard
ADR-023, proof graph ADR-032, targets board ADR-036, queue board ADR-066, ADR index
ADR-073). ADR-036 established *why* such refreshes run **post-merge**, not in each PR.
This decision extends that model from generated *files* to a generated *project board*.

## WH(Y) Decision Statement

**In the context of** decisions (ADRs) and work (issues) that have no single roadmap
view, where the pending ADRs — the `Proposed` ones — are precisely the work-ahead a
roadmap should surface,
**facing** the choice between a hand-maintained Project board (drifts the instant an ADR
is added or re-statused, because Projects v2 has no file→item sync) and curating one by
hand forever,
**we decided for** a generated **"unsorry Roadmap"** Project, populated from repo state
and reconciled by a `tools.project_sync` tool: every ADR becomes a draft item carrying
its literal `adrs.json` status in an **ADR Status** field (`Proposed`→`Pending`,
`Accepted`→`Accepted`, the sponsor-signed ADR-020→`Sponsored`), repo issues are linked
as live items, and a curated **Roadmap Stage** lane plus an **Item Type** and **ADR #**
field round out the schema; the tool enforces ADR Status / Item Type / ADR # from the
source of truth on every run but **never overwrites Roadmap Stage** once an item exists,
run by a `project-sync.yml` workflow that fires **after each `adr-index` refresh**
(`workflow_run`, when `adrs.json` is freshly regenerated — a `push` trigger would be
skipped by that workflow's `[skip ci]` commit) plus a periodic cron safety net and a
manual dispatch,
**and neglected** a hand-maintained board (drift), creating a real GitHub issue per ADR
(≈72 issues of repo noise and notifications, hard to undo — draft items keep the mirror
contained to the board), and an in-PR sync (no board state belongs in a PR, and it would
expose the project token to every PR run),
**to achieve** an always-current roadmap that surfaces the pending ADRs as the live
work-ahead and stays true to the same source of truth as the ADR index, self-maintaining
rather than a one-time snapshot,
**accepting that** the board is *eventually consistent* — briefly stale between a merge
and the sync run, acceptable for a derived view exactly as ADR-073 accepts for the index;
that the sync needs a `PROJECTS_TOKEN` secret (a PAT with the `project` scope, since the
default `GITHUB_TOKEN` cannot reach org-level Projects v2) and degrades to a report-only
warning when it is unset; that GitHub's built-in lifecycle workflows can only write the
*built-in* Status field, so issue **Roadmap Stage** is reconciled by the tool (closed→
`Done`, empty-open→`Backlog`) rather than by a native workflow; and that item identity is
keyed by ADR **file**, not number, because the corpus has two `ADR-041` files (the same
duplicate ADR-073's generator warns about).

## Consequences

- **Positive.** A reliable, self-updating roadmap across ADRs and issues; the pending
  (`Proposed`) ADRs are visible as the work-ahead; the board joins the one consistent
  generated-artifact model (ADR-023 / ADR-032 / ADR-036 / ADR-066 / ADR-073); the curated
  Roadmap Stage lane is safe from the sync; draft items keep the repo free of mirror
  issues.
- **Negative.** A brief window where the board lags a just-merged ADR change (bounded by
  the `workflow_run`/cron cadence); a new operational dependency on the `PROJECTS_TOKEN`
  secret (absent → the board simply isn't auto-reconciled; the workflow warns instead of
  failing); the board's existence/coordinates (`agenticsnz` project #1) are configuration
  the tool carries (env-overridable), not repo data.
- The `project-sync.yml` workflow lives under `.github/`, owned by `@cgbarlow`
  (ADR-019 / CODEOWNERS), so this change requires a code-owner review.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | project-sync tool + workflow spec | Specification | specs/SPEC-077-A-Project-Sync.md |
| REF-2 | The ADR index this syncs from (source of truth) | Decision | ADR-073-ADR-Index-Generated-README.md |
| REF-3 | The post-merge generated-artifact pattern this mirrors | Decision | ADR-036-Targets-Board-Post-Merge-Refresh.md |
| REF-4 | Generated-board precedents | Decision | ADR-023-Proof-Provenance-Leaderboard.md / ADR-066 (queue board) |
| REF-5 | CI supply-chain protection (owned `.github/`, pinned actions) | Decision | ADR-019-CI-Supply-Chain-Protection.md |
| REF-6 | Adopt Development Protocols (ADR/spec/WH(Y) process) | Decision | ADR-001-Adopt-Development-Protocols.md |
| REF-7 | Refresh-token push-to-`main` requirement (analogous secret model) | Issue | https://github.com/agenticsnz/unsorry/issues/417 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-20 |
