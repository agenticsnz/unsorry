# ADR-066: Queued-Proofs Board

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-066 |
| **Initiative** | proof-graph visualisation — queue observability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** the coordinated-submission model (ADR-058), where a
`--prove` agent in `UNSORRY_SUBMIT_MODE=queue` pushes a locally-verified proof to
a `queued/prove/<goal>/<agent>-<hex>` branch and a separate governor-metered
dispatcher (ADR-058/ADR-064) later opens those branches as PRs — so at any moment
hundreds of *finished, kernel-locally-verified* proofs sit in the queue, invisible
on the docs site, which only ever shows what has already merged to `main` (the
leaderboard #270 and the proof graph ADR-032),
**facing** the need for a public, at-a-glance view of *who has work in flight* —
the proofs submitted but not yet processed, grouped by solver — in the same
Tailwind/Inter UX as the existing home / leaderboard / proof-graph pages (ADR-038),
so contributors and onlookers can see the swarm's backlog and credit the solvers
whose proofs are queued behind the verifier,
**we decided for** a new generated page `docs/queue.html` (with a machine-readable
`docs/queue.json`) produced by a `tools.queue_board` generator that sources the
queue from **git refs** — `queued/prove/*` branches — rather than the `main`
working tree, resolves each submission's **solver** from the `⟦Π:Provenance⟧{solver≜…}`
block of the index entry the branch adds (the authoritative attribution, falling
back to the branch commit's git author via `docs/metrics/contributor-aliases.json`,
exactly as the leaderboard credits merged proofs, ADR-023/ADR-037), excludes goals
already proved on `main` (the `library/index` marker, matching the dispatcher's
ADR-064 dedup), and labels each submission **waiting** or **in-flight** from the
set of open prove-PR head refs supplied by the refreshing workflow,
**and neglected** (a) deriving the page post-merge on a push to `main` like the
other three generators — rejected because the queue is *not* a function of `main`'s
tree (it lives on ephemeral branches that fill and drain independent of any merge),
so a push-triggered `--check` would never reflect the queue and would either churn
on every refresh or go permanently stale; (b) attributing by the branch path's
`<agent>` segment — rejected because the agent id is not the GitHub solver (e.g.
`reroute-*` branches credit `ruvnet` via the index `solver≜`, not the bot that
pushed them); and (c) a live client-side page hitting the GitHub API on load —
rejected to keep the docs pages static, offline-capable, and consistent with the
existing generate-and-commit model,
**to achieve** a durable, regenerable picture of the submission backlog by solver
that reuses the existing record parsers and attribution helpers
(`tools.gate_b.records`, `tools.leaderboard.generate`) and the shared design
language, refreshed on a **schedule** (a cron cadence matching the dispatcher and
reaper) so it tracks the live queue,
**accepting that** the page is only as fresh as its last scheduled run (the queue
moves continuously between refreshes); the solver/proved/PR reads are best-effort
(a git or `gh` error degrades a submission to "waiting, solver unknown" rather than
dropping it, matching ADR-064's "selection must not depend on API health"); when
the open-PR head-ref set is unavailable every submission shows as `waiting` and the
page says so (no silent claim that nothing is in flight); and one extra scheduled
workflow runs on the `.github/` CODEOWNERS surface (ADR-019), landing via a
code-owner-reviewed PR.

## Context

This ADR is the queue-era companion to ADR-032. ADR-032 gave the swarm a generated
picture of the *merged* proof graph; ADR-058 then introduced a queue of locally
verified proofs that merge only later, through the metered dispatcher. That queue
is large (ADR-064 observed a 653-branch queue) and entirely invisible on the docs
site — there was no way to see who had proofs waiting behind the verifier.

The decisive structural difference from the three existing generators
(leaderboard, proof graph, targets board) is the **data source**. Those are pure
functions of the `main` working tree (plus, for the proof graph, the `prove(…)`
commits already on `main`), so they refresh post-merge and drift-check against the
tree. The queue board's input — the set of `queued/prove/*` refs and the index
entry each branch adds — exists only on branches, never in `main`'s tree, and
changes without any push to `main`. That forces two departures: the generator
reads `git for-each-ref` (degrading to empty outside a checkout, like ADR-032's
`git_provenance`), and the refresh is **scheduled** (ADR-036 is the post-merge
model; this is its scheduled sibling) rather than triggered by pushes to `main`.

Attribution reuses the leaderboard's precedence verbatim (ADR-023/ADR-037):
explicit `solver≜` from the index entry wins; otherwise the branch commit's git
author mapped through `contributor-aliases.json`. The "already proved on `main`"
exclusion reuses the dispatcher's own dedup signal (ADR-064) so the board and the
dispatcher agree on what counts as still-pending.

## Options Considered

### Option 1: Scheduled, git-ref-sourced generated page (Selected)
A `tools.queue_board` generator reading `queued/prove/*` refs + index provenance,
committed to `docs/queue.{html,json}` by a cron-scheduled workflow.
**Pros:** static/offline-capable and consistent with the existing
generate-and-commit pages; reuses the record parsers and attribution helpers;
honest about freshness and degraded reads; the only model that actually reflects a
queue that is not on `main`.
**Cons:** freshness is bounded by the cron cadence, not real-time; needs a new
scheduled workflow on the CODEOWNERS-protected `.github/` surface.

### Option 2: Post-merge refresh like ADR-032/ADR-036 (Rejected)
Trigger the refresh on pushes to `main` and drift-check with `--check`.
**Pros:** identical plumbing to the other three generators.
**Cons:** the queue is not a function of `main`, so a push-time `--check` cannot
see queue changes — the page would be permanently stale between unrelated merges,
and `--check` would be non-deterministic against live external branch state. Wrong
trigger for this data source.

### Option 3: Live client-side page calling the GitHub API (Rejected)
Ship a static shell that lists branches/PRs by calling the API in the browser.
**Pros:** always real-time; no generator or scheduled commit.
**Cons:** breaks the static, offline-capable, generate-and-commit model the other
pages follow; exposes rate limits and auth to the browser; cannot reuse the Python
attribution helpers, duplicating the solver-resolution logic in JS (DRY).

### Option 4: Attribute by the branch-path `<agent>` segment (Rejected)
Group submissions by the `<agent>-<hex>` segment of the branch name.
**Pros:** no need to read the branch's index entry.
**Cons:** the agent id is not the GitHub solver; `reroute-*` re-route branches
would mis-credit the bot rather than the real solver (`ruvnet`), contradicting the
leaderboard's attribution and ADR-037.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Extends | ADR-032 | Proof Graph Visualiser | Same generated-page pattern, helpers, and design language; new data source/trigger |
| Depends On | ADR-058 | Runner Pool Segmentation and Verification Capacity | The `queued/prove/*` queue this page observes |
| Depends On | ADR-023 | Proof Provenance and Leaderboard | `solver≜` provenance and the solver-resolution precedence |
| Relates To | ADR-064 | Goal-Level Dispatch Deduplication | "Already proved on `main`" / open-PR signals reused for the pending filter |
| Relates To | ADR-037 | Corroborated Solver Attribution | Alias fallback and not crediting the branch agent id |
| Relates To | ADR-038 | Leaderboard Design Language | Shared Tailwind/Inter card, nav, swatches |
| Relates To | ADR-036 | Post-Merge Artifact Refresh | This is the scheduled sibling of that post-merge model |
| Relates To | ADR-019 | CODEOWNERS-Protected Trust Surfaces | The new `.github/` workflow lands via code-owner review |
| Relates To | ADR-040 | Changelog Fragments | Ships a `changelog.d/` fragment |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-066-A — Queued-Proofs Board | Specification | specs/SPEC-066-A-Queued-Proofs-Board.md |
| REF-2 | Proof graph visualiser | Decision | ADR-032-Proof-Graph-Visualiser.md |
| REF-3 | Goal-level dispatch deduplication | Decision | ADR-064-Goal-Level-Dispatch-Deduplication.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
| Accepted | unsorry maintainers | 2026-06-17 |
