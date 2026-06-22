# ADR-082: Single-Pass Leaderboard Refresh (`--write-if-stale`)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-082 |
| **Initiative** | unsorry — generated-artifact handling under a high merge cadence |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-22 |
| **Status** | Accepted |

## Context

The community leaderboard artifacts (`docs/leaderboard.md` + `.svg`, `docs/proofs-over-time.svg`,
and `docs/metrics/*.json`) are regenerated **post-merge** by `.github/workflows/leaderboard.yml`
running `tools.leaderboard` (ADR-036 model, ADR-023 data model). The downstream engagement
surface — `agenticsnz/unsorry-guild` — reads `docs/metrics/leaderboard-ui.json` live, so the
freshness a contributor sees is bounded by how quickly that file is refreshed on `main`.

The leaderboard regen is the **heaviest** of the three post-merge refreshers: a CPU-bound
recompute of contributor/rate/attribution stats over the whole **active + archive** corpus
(ADR-041 archive blocks; ~2,573 distinct proofs and growing), plus a merge-time timeline that
scans `prove(…)` history. ADR-036's own #426 update already named it as the one being starved.
Measured on `main` (2026-06-22), a single `tools.leaderboard` invocation takes **~10 min**.

The workflow recomputed the corpus **twice per refresh**: a standalone `--check` step to set a
`stale` output, then — on drift — a separate `--write` step. That ~21 min of compute per refresh
(a) doubled the window during which `main` advances mid-refresh, so the board could only land a
fresh snapshot roughly every ~25–30 min and `leaderboard-ui.json`'s `generated_at` visibly lagged
the latest merges, and (b) wasted CI runner minutes. The `--check`/`--write`/`--json` modes are a
**pure function** of the inputs and `--write` is deterministic and idempotent (its `generated_at`
is keyed to the latest *source* commit, not wall-clock — SPEC-023-A), so the two passes always
agree; the second recompute carries no information the first didn't.

## WH(Y) Decision Statement

**In the context of** a post-merge leaderboard refresh whose regen has grown to ~10 min over the
active+archive corpus, feeding a live engagement surface (unsorry-guild) that reads
`docs/metrics/leaderboard-ui.json`,
**facing** a workflow that recomputes the whole corpus **twice** per refresh (a `--check` drift
probe followed by a `--write`), which doubles the mid-refresh window so the board lands a fresh
snapshot only every ~25–30 min and its `generated_at` lags the merge firehose, and burns double
the CI runner time,
**we decided for** adding a single-pass `tools.leaderboard --write-if-stale` mode — it computes the
artifacts **exactly once**, writes them iff they drifted, and signals drift via its exit code
(`1` = was stale and rewritten, `0` = already in sync, mirroring `--check`) — and rewiring
`leaderboard.yml` to call it once (replacing the separate `--check` + `--write` steps), keeping the
unchanged #426 cheap-push-retry/rebase loop and routing the degraded no-`REFRESH_TOKEN` path to its
own one-shot read-only `--check`,
**and neglected** keeping the two-pass `--check`-then-`--write` (the wasted second recompute and the
doubled staleness window it causes); a `--write`-then-`git diff` shell heuristic in the workflow
(less explicit, untestable as a unit, and duplicates the tool's own staleness definition in bash);
and speeding the regen itself (orthogonal and larger — this ADR is the cheap, sound halving that
lands first),
**to achieve** a single ~10-min recompute per refresh (never more than before, strictly fewer on the
hot path), halving the mid-refresh window so the published board — and the guild graph reading it —
tracks the merge firehose roughly twice as closely, and freeing CI runner time,
**accepting that** a no-drift tick still pays one recompute (unchanged), the pushed snapshot still
reflects `main` as of regen start (a few proofs merged during the regen land on the next push/tick,
exactly as under ADR-036/#426), and the rare rebase-conflict fallback pays one extra single-pass
regen (bounded, and only when the disjoint-paths invariant is violated).

## Consequences

- **Positive.** Halves the hot-path compute and the mid-refresh staleness window with no change to
  the artifacts produced; reduces CI runner minutes; `--write-if-stale` is a reusable single-pass
  primitive the lighter refreshers could adopt later. The change is soundness-neutral — it touches
  only generated human-facing artifacts, never the library, proofs, or gates.
- **Negative / residual.** The underlying ~10-min regen is unchanged, so the board can still lag by
  roughly one regen during a sustained burst; the deeper fix (incremental/cached regen) is deferred.
- **Refines** ADR-036's post-merge model (does not supersede it): same trigger, same push model,
  one recompute instead of two.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Single-pass refresh spec | Specification | specs/SPEC-082-A-Single-Pass-Leaderboard-Refresh.md |
| REF-2 | Post-merge generated-artifact model this refines | Decision | ADR-036-Targets-Board-Post-Merge-Refresh.md |
| REF-3 | Leaderboard data model + determinism (`generated_at`) | Decision/Spec | ADR-023-Proof-Provenance-Leaderboard.md · specs/SPEC-023-A-Proof-Provenance-Leaderboard.md |
| REF-4 | Why the corpus (and thus the regen) is large: archive blocks | Decision | ADR-041-Proof-Archive-Blocks.md |
| REF-5 | Cheap-push-retry / regen-once predecessor | Issue/CI | https://github.com/agenticsnz/unsorry/issues/426 · `.github/workflows/leaderboard.yml` |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-22 |
| Accepted | unsorry maintainers | 2026-06-22 |
