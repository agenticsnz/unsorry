# SPEC-089-A: Scheduled GitHub Pages Deploy via Actions

Implements: [ADR-089](../ADR-089-Pages-Scheduled-Actions-Deploy.md) · Status: Living · Updated: 2026-06-23

ADR-089 moves the Pages site off the legacy push-triggered build (which livelocks
under the swarm's push firehose) onto a GitHub Actions deploy driven by a fixed
cadence. This spec is the contract for the workflow, the one-time source flip,
the rollout sequence, and how the fix is verified.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | Scheduled Pages deploy workflow | `.github/workflows/pages-deploy.yml` | **yes** (`/.github/` → @cgbarlow) |
| D2 | Pages source flipped `legacy` → `workflow` | repo *setting* (Settings → Pages → Source = "GitHub Actions") | n/a (setting, not a file) |
| D3 | Changelog fragment | `changelog.d/fixed-pages-deploy-livelock.md` | no |

## 2. Workflow contract (D1)

`.github/workflows/pages-deploy.yml` MUST:

- **Triggers** — `schedule: "*/10 * * * *"` and `workflow_dispatch`. It MUST NOT
  trigger `on: push` (any branch/path). The absence of a push trigger is the
  load-bearing property: it is what decouples deploys from the firehose.
- **Permissions** — least privilege: `contents: read`, `pages: write`,
  `id-token: write` (the set the official Pages deploy actions require).
- **Concurrency** — `group: pages`, `cancel-in-progress: false`. A run is never
  preempted; a second run (cron tick or manual) queues behind an in-flight one.
  `cancel-in-progress: true` is FORBIDDEN — for a deploy it re-creates the bug.
- **Build** — `actions/checkout@v4` → `actions/configure-pages@v5` →
  `actions/jekyll-build-pages@v1` (`source: ./`, `destination: ./_site`) →
  `actions/upload-pages-artifact@v3`. Using the github-pages gem keeps output
  identical to the legacy build under the root `_config.yml` (same exclude list).
- **Deploy** — a `deploy` job `needs: build`, environment `github-pages`, using
  `actions/deploy-pages@v4`.

Cadence rationale: the build comfortably finishes inside 10 minutes, so with
`cancel-in-progress: false` consecutive runs never overlap and every run
completes. Interval is a freshness↔frequency dial; `*/10` bounds staleness at
~10 min. `workflow_dispatch` is the on-demand "deploy now".

## 3. Pages source flip (D2)

The repo Pages **Source** must change from "Deploy from a branch" (`main` `/`) to
"GitHub Actions" — equivalently `build_type: workflow`. This is a repository
setting, so it is NOT carried by the PR diff and NOT gated by CODEOWNERS; it is a
maintainer action at rollout. Effect: GitHub stops the legacy auto-build
entirely (no more per-push `pages-build-deployment` runs → livelock ends) and
routes deploys through the `github-pages` environment that `deploy-pages` targets.

Flip via either:

- UI — Settings → Pages → Build and deployment → Source → **GitHub Actions**; or
- API — `gh api -X PUT repos/agenticsnz/unsorry/pages -f build_type=workflow`.

## 4. Rollout sequence

Order matters because `deploy-pages` requires `build_type: workflow`:

1. **Merge** this PR (code-owner approved; `.github/` surface). The workflow now
   exists on `main`. Legacy build is still active until step 2.
2. **Flip** the Pages source to GitHub Actions (D2). This immediately stops the
   legacy livelock.
3. **Dispatch** a first deploy now rather than waiting for the next cron tick:
   `gh workflow run pages-deploy.yml --ref main`.
4. **Verify** (§5). Thereafter the cron drives it.

A brief window exists between steps 1 and 2 where the new workflow could fire on
cron while Pages is still `legacy`; its `deploy` step would error harmlessly.
Performing steps 2–3 right after merge keeps that window to seconds.

## 5. Verification (operational; no unit test for a deploy workflow)

A YAML deploy workflow has no meaningful unit test; verification is operational
and matches how other ops workflows in this repo are validated (live run + state
check):

- **V1 — first deploy succeeds.** After §4.3, the `pages-deploy` run is green and
  the `github-pages` deployment for the dispatched SHA has status `success` (not
  `error`). Spot-check the live site reflects a recent `main` (e.g. a known
  recent README/site change is present).
- **V2 — livelock gone.** No new `pages-build-deployment` (legacy) runs are
  created after the flip: `gh run list --workflow pages-build-deployment` shows
  nothing newer than the flip time.
- **V3 — cadence holds.** Over the following ~30 min, `pages-deploy` runs appear
  ~every 10 min and each `conclusion` is `success` (none `cancelled`).
- **V4 — output parity.** The deployed site renders the same as the intended
  legacy output (homepage = README, Lean/tooling tree excluded per `_config.yml`).

Static check before merge: the workflow is valid YAML and uses pinned official
action majors (`@v4`/`@v5`/`@v1`).

## 6. Out of scope

- **"Skip deploy if site unchanged"** — the cron does ~144 no-op redeploys/day.
  Cheap relative to the cancelled-build firehose; an unchanged-content guard is a
  possible later optimisation, deliberately omitted now (KISS).
- **Tightening/relaxing the interval** — `*/10` is the chosen default; changing
  it is a one-line follow-up, not a re-decision.
- **Migrating to a dedicated build branch** — considered and rejected in ADR-089.
- **Any change to swarm push behaviour, `_config.yml`, or site content.**
