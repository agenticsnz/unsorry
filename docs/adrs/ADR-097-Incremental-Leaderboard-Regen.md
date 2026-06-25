# ADR-097: Per-Generation Leaderboard Regen (directory-scoped attribution + memoised loaders)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-097 |
| **Initiative** | unsorry — leaderboard regen runtime under a high merge cadence |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-25 |
| **Status** | Accepted |

## Context

The community leaderboard artifacts (`docs/leaderboard.md` + `.svg`, `docs/proofs-over-time.svg`,
and `docs/metrics/*.json`) are regenerated **post-merge** by `.github/workflows/leaderboard.yml`
running `tools.leaderboard` (ADR-036 model, ADR-023 data model, single-pass `--write-if-stale`
per ADR-082). The downstream engagement surface — `agenticsnz/unsorry-guild` — reads
`docs/metrics/leaderboard-ui.json` live, so the freshness a contributor sees is bounded by how
quickly that file lands on `main`.

ADR-082 halved the refresh by recomputing the corpus once instead of twice, but explicitly
**deferred the deeper fix** (speeding the regen itself) and recorded the residual: "the board can
still lag by roughly one regen during a sustained burst." By 2026-06-25 that residual had become
the dominant failure (issue #6317): with the corpus grown to ~4,000 verified proofs / ~1,200
proof-runs, a single regen measured **~64 min**. At the swarm's merge cadence of one merge per
~1–2 min, a 64-min in-progress refresh is lapped by ~40 merges, its push loses the race, and the
board starved for **hours** — exactly when the board matters most.

Profiling the regen on the live corpus isolated two compounding causes, neither of them the
per-record arithmetic:

1. **Git attribution was O(history × corpus).** `git_add_authors` / `goal_add_authors` passed one
   pathspec **per proof / per goal** (~4,000 literal paths) to `git log --diff-filter=A`. Over
   ~14k commits that pathspec matching took **~86 s for a single call** — and the call is made ~9×
   across the renderers. Measured: the identical walk scoped to the parent **directory**
   (`library/index`, `goals`) — every attribution path lives under one of them — returns in **~0.7 s**.
2. **Every loader ran ~4–9×.** `base_stats` is recomputed once for each of the markdown /
   community-stats / leaderboard-ui / svg renderers, and `load_dataset` (which parses ~9k AISP
   records, **~14 s**) plus the git walks re-ran each time. The repetition, not the parse, was the
   cost.

These are pure-function recomputations: the regen is a deterministic function of
`goals/ + library/index + proof-runs/ + archive + aliases + git history` (SPEC-023-A), so the
result is invariant under deduplicating the work.

## WH(Y) Decision Statement

**In the context of** a post-merge leaderboard refresh feeding a live engagement surface, whose
single recompute had grown to ~64 min over the active+archive corpus,
**facing** a regen that (a) walks git add-author history with ~4,000 individual pathspecs, making
`git log` O(history × corpus) at ~86 s/call ×~9 calls, and (b) re-parses the whole corpus and
re-walks attribution ~4–9× because `base_stats` is recomputed per rendered artifact — so the board
starves for hours under a sustained merge flood (the push-on-merge refresh is lapped before it can
land),
**we decided for** making the regen **per-generation incremental in work, not in result**: scope
each git add-author walk to the parent **directory** (`library/index`, `goals`) and filter the
streamed adds in Python to the wanted set (identical output, ~86 s → ~0.7 s); and **memoise** the
corpus loaders (`goals`, `proofs`, `runs`, `load_dataset`, `merge_times`, `git_add_authors`,
`goal_add_authors`) for the lifetime of **one** top-level generation, so each record is parsed once
and each attribution walked once across all renderers,
**and neglected** a persistent on-disk delta cache of intermediate aggregates between CI runs (a
real cache-invalidation surface — staleness bugs, an artifact to version and key on toolchain +
corpus state — for no extra speed once the regen is already seconds); a process-lifetime memo with
no scope (correct for the one-shot CLI but a latent staleness footgun for any in-process re-compute
after a corpus change, e.g. the workflow's rebase-and-regen retry or a unit test); and the
defence-in-depth items from the issue (a dedicated serialized refresh worker, a self-rescheduling
cron backstop, a `timeout-minutes` + alert) — orthogonal hardening, not the root-cause fix, left to
a follow-up,
**to achieve** a full-corpus regen of **~10 s** (measured, down from ~64 min — ~370×), restoring
the push-on-merge model the design assumes: a refresh now comfortably outpaces a 1-merge/1–2-min
flood, so `leaderboard-ui.json` `generated_at` tracks `main` within minutes instead of hours,
**accepting that** the speed is bounded by one corpus parse + a few directory-scoped git walks
(O(corpus), not O(delta)) — fast enough that a persistent delta cache earns nothing — and that the
memo is correct **only** because its lifetime is scoped to one outermost call (a depth-guard clears
it on entry/exit), so any function that recomputes after mutating the corpus in-process must do so
through a fresh top-level call (it always does: the CLI is one-shot, the workflow retry re-invokes
`main`, and the loaders self-scope so even a direct library call re-reads the tree).

## Consequences

- **Positive.** ~370× faster regen with **byte-identical artifacts** (verified: directory-scoped
  attribution equals the per-file output on the live history, and the SPEC-023-A golden tests are
  unchanged). The board tracks the merge firehose within minutes; the #426 cheap-push-retry loop
  now actually converges because each regen is seconds, not an hour. Soundness-neutral — touches
  only the generated human-facing artifacts, never the library, proofs, or gates.
- **Negative / residual.** Regen is still O(corpus) per run (one parse + the directory walks), not
  O(delta); at far larger corpus scales a persistent aggregate cache may become worthwhile — but
  not at the current ~10 s. The board can still lag by ~one (now seconds-long) regen during a
  burst. The defence-in-depth net (serialized worker, self-rescheduling backstop, timeout/alert)
  from issue #6317 is **deferred**, so a stalled pipeline is still only made *visible* by the
  guild-side `generated_at` freshness indicator, not yet alerted at source.
- **Refines** ADR-082 (does not supersede it): same single-pass `--write-if-stale` shape and the
  same trigger/push model; this ADR delivers the "speeding the regen itself" that ADR-082 named as
  the deferred, larger follow-up.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Per-generation regen spec | Specification | specs/SPEC-097-A-Incremental-Leaderboard-Regen.md |
| REF-2 | Single-pass refresh this follows up (deferred the regen-speed fix) | Decision | ADR-082-Single-Pass-Leaderboard-Refresh.md |
| REF-3 | Post-merge generated-artifact model | Decision | ADR-036-Targets-Board-Post-Merge-Refresh.md |
| REF-4 | Leaderboard data model + determinism (`generated_at`, golden output) | Decision/Spec | ADR-023-Proof-Provenance-Leaderboard.md · specs/SPEC-023-A-Proof-Provenance-Leaderboard.md |
| REF-5 | Why the corpus (and thus the regen) is large: archive blocks | Decision | ADR-041-Proof-Archive-Blocks.md |
| REF-6 | Diagnosis + acceptance criteria | Issue | https://github.com/agenticsnz/unsorry/issues/6317 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-25 |
| Accepted | unsorry maintainers | 2026-06-25 |
