# SPEC-077-A: Roadmap Project Sync

Implements: [ADR-077](../ADR-077-Roadmap-Project-Synced-From-Repo-State.md) · Status: Living · Updated: 2026-06-20

## What this adds

A tool that reconciles the **"unsorry Roadmap"** GitHub Project (Projects v2) from repo
state, plus a workflow that runs it after every ADR-index refresh.

- **`tools/project_sync/`** (`sync.py` + `__main__.py`), tests in `tools/project_sync/tests/`.
- **`.github/workflows/project-sync.yml`** — `workflow_run`-after-`adr-index` + cron + dispatch.
- **No committed artifact.** Unlike the generated *files* (ADR-073 etc.), the output is
  the live Project board; there is nothing to commit or byte-compare.

## The board

| Thing | Value |
|---|---|
| Owner / number | `agenticsnz` org, project `#1` (env `PROJECT_OWNER` / `PROJECT_NUMBER`) |
| Custom field **ADR Status** | single-select: `Pending` · `Accepted` · `Sponsored` |
| Custom field **Roadmap Stage** | single-select: `Backlog` · `Planned` · `In Progress` · `Done` (curated) |
| Custom field **Item Type** | single-select: `ADR` · `Issue` |
| Custom field **ADR #** | number |

Field and option **IDs are resolved by name at runtime** (a `fields` GraphQL query), never
hard-coded — a recreated project with the same field/option names Just Works.

## Item identity

- **ADRs** are draft items keyed by their **file** (`adr["file"]`), recovered from the
  draft body's Markdown link (`[<file>](…)`). Keying by file — not by `ADR-NNN` number —
  is required because the corpus has two `ADR-041` files (the duplicate ADR-073's
  generator warns about); a number key would collide and thrash their titles forever.
- **Issues** are linked items, identified by their content node id (added live or by the
  built-in auto-add workflow).

## Reconcile rules (pure, unit-tested)

Source: `docs/adrs/adrs.json` (`adrs[]` with `id, number, title, status, date, file`).

**ADRs** — for each entry, against the board snapshot keyed by file:
- **missing** → `create_adr`: a draft titled `"<id> — <title>"` with a body linking the
  file; set `ADR Status` (`desired_adr_status`), **seed** `Roadmap Stage`
  (`Pending`→`Backlog`, else `Done`), `Item Type=ADR`, `ADR #`.
- **present** → enforce only what is the source of truth: set `ADR Status` if it differs
  (this is what carries a `Proposed`→`Accepted` flip onto the board), backfill
  `Item Type`/`ADR #` if missing, and `set_title` if the ADR was renamed.
- **`Roadmap Stage` is never written on update** — it is the maintainer's curated lane.

`desired_adr_status`: `"sponsor"` in status → `Sponsored`; starts `Proposed` → `Pending`;
otherwise → `Accepted`.

**Issue items** already on the board:
- backfill `Item Type=Issue` if unset;
- `CLOSED` and stage ≠ `Done` → set `Done`;
- `OPEN` with no stage → seed `Backlog`; an open issue that already has a stage is left
  alone (respects triage).

Every rule is idempotent: a second run with no repo change plans nothing.

## CLI

```
python3 -m tools.project_sync --check [<root>]   # report drift, exit 1 if any, else 0
python3 -m tools.project_sync --sync  [<root>]   # apply the plan
python3 -m tools.project_sync --plan  [<root>]   # print the plan as JSON (read-only)
```

`<root>` defaults to `.`; the mode flags are mutually exclusive (zero or two → exit 2).
If the board is unreachable (e.g. `GH_TOKEN`/`PROJECTS_TOKEN` unset, transient API error),
the tool prints a `::warning::` and exits **0** — it degrades, it does not fail the build.

## Transport

The only I/O is `gh api graphql` (a single `Client` seam, mockable in tests): a `fields`
query (schema), a paginated `items` query (current state + field values), and batched
`updateProjectV2ItemFieldValue` / `addProjectV2DraftIssue` / `updateProjectV2DraftIssue`
mutations. Transient errors (`temporary conflict`, secondary rate limits) retry with
exponential backoff.

## Workflow (`project-sync.yml`)

Triggers: `workflow_run` on `adr-index` `completed` (fires when `adrs.json` is fresh — a
`push` trigger would be skipped by `adr-index`'s `[skip ci]` refresh commit), a
`schedule` cron (`17 * * * *`, hourly, for issue lifecycle and as a safety net), and
`workflow_dispatch`. `concurrency: { group: project-sync, cancel-in-progress: false }`;
`permissions: contents: read`; pinned action SHAs (ADR-019).

Auth: `GH_TOKEN: ${{ secrets.PROJECTS_TOKEN }}` (a PAT with the `project` scope — the
default `GITHUB_TOKEN` cannot reach org-level Projects v2). When the secret is unset the
job emits a report-only `::warning::` instead of running (graceful-degrade, like
adr-index.yml / #417).

## Acceptance criteria

1. On the in-sync board, `python3 -m tools.project_sync --check .` exits 0.
2. Adding an ADR to `adrs.json` makes `--check` exit 1 with a `create draft …` action;
   `--sync` creates the draft with ADR Status/Item Type/ADR # set and Roadmap Stage seeded.
3. Flipping an ADR `Proposed`→`Accepted` plans exactly an `ADR Status` set — **never** a
   `Roadmap Stage` change.
4. The two `ADR-041` files remain two distinct items; neither retitles the other.
5. A closed issue item reconciles to `Roadmap Stage=Done`; an open, already-triaged issue
   is left unchanged.
6. A second `--sync` with no repo change plans zero actions (idempotent).
7. Missing `PROJECTS_TOKEN`/unreachable board → `--sync` warns and exits 0.
8. `python3 -m pytest tools/project_sync -q` is green; Gate B (`tools.gate_b validate .`)
   passes; `project-sync.yml` is valid, pinned, and `permissions: contents: read`.
