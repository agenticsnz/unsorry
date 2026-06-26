# ADR-089: Deploy GitHub Pages on a Schedule via Actions, Decoupled from the Push Firehose

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-089 |
| **Initiative** | site delivery & infrastructure |
| **Proposed By** | Chris Barlow (maintainer) |
| **Date** | 2026-06-23 |
| **Status** | Accepted |

## Context

The public site (`unsorry.agentics.org.nz`, served from this repo's GitHub Pages)
is configured with the **legacy** build source: `build_type: legacy`, source =
`main` branch, path `/`. GitHub's legacy Pages build auto-rebuilds on **every
push** to the source branch and **cancels any in-flight build** when a newer push
arrives.

That cancellation policy is fatal here because of how this repo is written to.
The swarm merges to `main` continuously — a commit every **~10–60 seconds**
(proof merges plus leaderboard/SVG/`leaderboard-ui.json` refreshes). A legacy
Pages build takes **~30–120 seconds**. So every build is preempted by the next
push before it can deploy. This is a **livelock, not slowness**.

Measured 2026-06-23 (~21:57 NZT):

- The last **200** `pages-build-deployment` runs (back ~3h to 06:57Z) were **all
  `cancelled`** — zero successes.
- Every `github-pages` environment deployment in that window has latest status
  **`error`**; the Pages site reports `status: errored`.
- The live site is therefore frozen on whatever last deployed successfully (3h+
  ago, likely longer), and **no docs/site change reaches production** — including
  a README change merged minutes earlier.

There is no per-build knob on the legacy source: it always rebuilds on push and
always cancels in-progress. The only way to gain control of triggers and
concurrency is to move Pages onto the **GitHub Actions** build source, where the
deploy is an ordinary workflow we own.

This is a distinct failure from [ADR-082](ADR-082-Single-Pass-Leaderboard-Refresh.md)'s
leaderboard staleness (that was regen *duration*); here the regenerated artifacts
are fine — the **Pages deploy pipeline itself** never completes.

## WH(Y) Decision Statement

**In the context of** a Pages site on the legacy build source that auto-rebuilds
on every push to `main` and cancels the in-flight build, sitting in front of a
swarm that pushes to `main` every ~10–60s while a build takes ~30–120s,

**facing** a permanent livelock — 200+ consecutive Pages builds all cancelled,
every deployment `error`, the live site frozen for hours, and no site/docs change
(README links, showcase, narrative) ever reaching production — with no
trigger/concurrency control available on the legacy source,

**we decided for** moving Pages to the **GitHub Actions** build source and owning
the deploy as a workflow (`.github/workflows/pages-deploy.yml`) that is

1. triggered on a **fixed cadence** (`schedule: */10 * * * *`) plus
   `workflow_dispatch` for an on-demand "deploy now", and **never on `push`**, so
   the swarm's commits can neither trigger nor preempt a deploy;
2. guarded by `concurrency: { group: pages, cancel-in-progress: false }`, so a
   run is never cancelled mid-flight (the exact behaviour that broke the legacy
   build) and at most queues behind one already deploying;
3. built with `actions/jekyll-build-pages` (the github-pages gem) so the output
   is identical to the legacy build under the same root `_config.yml`,

**and neglected** keeping the legacy source (rejected — it offers no way to stop
per-push rebuilds or in-flight cancellation, the two properties that cause the
livelock); an Actions workflow triggered `on: push` with path filters
(rejected — the swarm's leaderboard/SVG refreshes touch site paths often enough
to reintroduce preemption, and `cancel-in-progress` would re-create the livelock
under our own control); `cancel-in-progress: true` to coalesce (rejected — for a
*deploy* that means newer runs keep killing the run that would have shipped, the
original bug); throttling the swarm's pushes to `main` (rejected — the firehose
is the product, ADR-004/005; the site must tolerate it, not constrain it); and a
dedicated `gh-pages` build branch fed by a path-filtered job (rejected as more
moving parts than needed — a cadence cap already fully decouples deploys from the
firehose).

## What this changes (summary; full contract in SPEC-089-A)

- **Pages source** — flip the repository Pages setting from `build_type: legacy`
  to `build_type: workflow` (Settings → Pages → Source = "GitHub Actions"). This
  is a repo *setting*, not a file; it is a one-time rollout step, performed at
  merge time (see SPEC-089-A §Rollout). Flipping it also **stops the legacy
  auto-build**, ending the livelock immediately.
- **New workflow** — add `.github/workflows/pages-deploy.yml`: `schedule`
  (`*/10`) + `workflow_dispatch`, least-privilege `pages`/`id-token` permissions,
  `concurrency: pages` with `cancel-in-progress: false`, build via
  `actions/jekyll-build-pages`, deploy via `actions/deploy-pages`. This file is
  under `.github/`, a **CODEOWNERS** surface, so the PR needs code-owner approval.
- **No change** to `_config.yml`, site content, the swarm, or any other workflow.
  The legacy `pages-build-deployment` runs simply stop once the source is flipped.

## Consequences

- **Positive — the livelock ends.** Deploys are capped at one per cron tick and
  are never cancelled, so each runs to completion; the live site can never again
  be starved by push frequency.
- **Positive.** Site freshness becomes bounded and predictable: at most ~10 min
  behind `main`, with `workflow_dispatch` as an immediate manual deploy.
- **Positive.** Output is byte-equivalent to today's intended site
  (`jekyll-build-pages` = the github-pages gem, same root `_config.yml`).
- **Positive.** Stops burning CI on dozens of cancelled `pages-build-deployment`
  runs per hour.
- **Negative / trade-off.** The site is no longer "instant on push" — a change
  can take up to the cron interval (~10 min) to appear. Acceptable for a
  near-static docs/marketing site, and `workflow_dispatch` covers urgent deploys.
  Tightening the interval trades freshness for more frequent builds.
- **Negative.** The cron runs ~144 deploys/day even when nothing changed (Jekyll
  output is deterministic, so these are no-op redeploys). Far cheaper than the
  current firehose of cancelled builds; a "skip if unchanged" guard is possible
  later but deliberately omitted now (KISS).
- **Operational.** The source flip is a manual setting change (CODEOWNERS PR gates
  the *workflow*, not the setting). Until the flip, the new workflow's deploy step
  cannot succeed (Pages still legacy); the rollout sequence in SPEC-089-A merges,
  flips, then dispatches a first deploy to verify.
- **Reversibility.** Fully reversible: flip the Pages source back to "Deploy from
  a branch" and delete the workflow.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Pages scheduled Actions deploy spec | Specification | specs/SPEC-089-A-Pages-Scheduled-Actions-Deploy.md |
| REF-2 | Claims on dedicated branch / autonomous merge to main (the push firehose) | Decision | ADR-004 / ADR-005 |
| REF-3 | Single-pass leaderboard refresh (distinct staleness fix) | Decision | ADR-082-Single-Pass-Leaderboard-Refresh.md |
| REF-4 | Jekyll site config & exclude tree | Implementation | _config.yml |
| REF-5 | GitHub Pages with Actions (configure-pages / jekyll-build-pages / deploy-pages) | External | https://github.com/actions/deploy-pages |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | Chris Barlow | 2026-06-23 |
| Accepted (workflow added; Pages source flip is the merge-time rollout step) | Chris Barlow | 2026-06-23 |
