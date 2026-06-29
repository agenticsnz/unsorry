# ADR-111: Carry the Proofs-Over-Time Chart Forward Across Quiet Gaps

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-111 |
| **Initiative** | unsorry — leaderboard legibility |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-29 |
| **Status** | Accepted |

## Context

`docs/proofs-over-time.svg` (rendered by `tools/leaderboard/generate.py:render_timeline_svg`,
ADR-023 data, ADR-082/101 refresh) plots cumulative kernel-verified proofs by the hour each
landed on `main`. Its x-axis domain runs from the first proof bucket to the **last proof
bucket** — so the right edge is the most recent *proof*, not the most recent *moment*.

When the swarm goes quiet (no proofs land for a stretch — e.g. proving agents offline, or a
run of failed attempts), the chart's right edge simply stops at the last proof. A reader
cannot distinguish **"alive, but no new proofs"** from **"the chart/pipeline froze"**: the
axis ending at `Jun 26 15:00` reads as staleness even when the board itself is fresh and the
generator is running every cycle. Observed 2026-06-29: a ~63 h proof drought left the chart
ending at `Jun 26 15:00` (03:00 NZST — "0300"), reported as a stale leaderboard when in fact
the board's `generated_at` and freshness gate (ADR-098) were green; the swarm had simply not
*landed* a proof (the producer was offline and a backlog was flake-blocked on Gate A).

The board's *standings* freshness is already covered (ADR-098 measures lag of `generated_at`
vs the latest board-source commit). What is missing is that the **time-series chart** has no
way to show a no-growth-but-live interval.

A naïve fix — anchor the right edge to wall-clock `now` — would break determinism: the SVG
would change on every regen even with no input change, defeating ADR-082's `--write-if-stale`
no-churn contract and committing `proofs-over-time.svg` on every tick.

## WH(Y) Decision Statement

**In the context of** the proofs-over-time chart's x-axis ending at the last proof bucket,

**facing** a quiet stretch (no proofs landing) being visually indistinguishable from a frozen
chart — the axis stops at the last proof and reads as stale even when the board is fresh,

**we decided for** anchoring the chart's right edge to the **latest board-source commit
timestamp** (`_latest_source_commit_z` — the same value that keys `generated_at`, SPEC-023-A),
floored to the series' bucket resolution; when that activity is at least one bucket later than
the last proof, the line is **carried flat to the right edge as a dashed segment** with an
edge x-tick at the activity time, and the subtitle gains a `· last proof <ts> UTC` annotation,

**and neglected** anchoring to wall-clock `now` (rejected — non-deterministic; churns the SVG
every tick and breaks `--write-if-stale`), excluding the chart from the board (rejected — it
is the headline engagement card), and adding a separate "staleness" badge to the chart
(rejected — staleness is the board's `generated_at` concern, ADR-098; the chart should show
*activity*, and the carry-forward conveys "live but quiet" without duplicating the gate),

**to achieve** a chart on which a no-new-proofs interval renders as an explicit flat dashed
carry-forward ("alive, no new proofs") rather than a stopped axis, and an explicit last-proof
timestamp in the subtitle,

**accepting that** the rendered SVG now changes whenever the latest board-source commit
crosses into a new bucket — but only ever in lockstep with a commit that *already* regenerates
and commits the board (`_latest_source_commit_z` bumps on input merges, never on the refresh's
own docs-only commit), so it adds **zero** new commits; and that the solve (daily) fallback,
used only outside a git checkout, carries forward at day resolution.

## Decision

- `render_timeline_svg` reads `_latest_source_commit_z(root)`, floors it to the series bucket
  resolution (hour for the merge series, day for the solve fallback) and to the series'
  tz-awareness, and extends the x-domain to it **only when** it is strictly later than the last
  proof bucket. Otherwise the render is byte-identical to the pre-ADR-111 shape.
- On a gap: a dashed grey carry-forward segment is drawn from the last point to the right edge
  at the same y (the count does not move), with an edge x-tick at the activity time.
- The subtitle gains `· last proof <Mon DD HH:00> UTC` for the merge series.

## Consequences

- A quiet interval is legible as "live, no new proofs", not "frozen".
- Determinism preserved: the SVG is a pure function of the corpus + git history; it changes
  only when an input merge (which already drives a regen + commit) moves the activity bucket —
  no new commits, `--check` stays clean.
- Outside a git checkout (`_latest_source_commit_z` is `None`) the chart is unchanged.
