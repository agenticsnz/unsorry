# SPEC-101-A: Per-Generation Leaderboard Regen

Implements: [ADR-101](../ADR-101-Incremental-Leaderboard-Regen.md) · Follows up [SPEC-082-A](SPEC-082-A-Single-Pass-Leaderboard-Refresh.md) (single-pass refresh) · Preserves [SPEC-023-A](SPEC-023-A-Proof-Provenance-Leaderboard.md) (data model + determinism) · Status: Living · Updated: 2026-06-25

## What changed

A single `tools.leaderboard` regen over the live corpus drops from **~64 min to ~10 s** while
producing **byte-identical** artifacts. Two changes in `tools/leaderboard/generate.py`, no change
to the artifacts, the CLI surface, the trigger model, or the determinism guarantees of SPEC-023-A.

### 1. Directory-scoped git add-author attribution

`git_add_authors(root, proof_data)` and `goal_add_authors(root, goal_ids)` previously passed one
pathspec **per record** (~4,000 literal paths) to `git log --diff-filter=A --name-only …`. That
made pathspec matching O(history × corpus) — ~86 s per call on the live history, ×~9 calls per
regen.

They now pass a **single directory pathspec** and filter the streamed adds in Python:

- `git_add_authors` walks `library/index` (every attribution path is under it — active records sit
  there, and archived records remap to `library/index/<basename>` via `_git_attribution_path`).
- `goal_add_authors` walks `goals`.

The downstream parse is unchanged: stream `\x1e<commit>\x1f<name>\x1f<email>\x1f<date>` headers and
`--name-only` paths, keep only `path in wanted`, and (newest-first ⇒ last assignment wins) retain
the **earliest** add commit per path. Because the per-path set of add-events is identical under a
file pathspec and its parent-directory pathspec, the returned `{path → GitAuthor}` map is identical.

### 2. Per-generation memoised loaders

The corpus loaders are memoised so one generation does the work once and every renderer reuses it:

- Memoised: `goals`, `proofs`, `runs`, `load_dataset`, `merge_times`, `git_add_authors`,
  `goal_add_authors` (decorated `@_scoped` over `@_memo_by_root`).
- `@_memo_by_root` keys the cache on `str(Path(root).resolve())`. Sound because every loader is a
  pure function of `root` — its other arguments are themselves derived from `root` (`known_goals`
  is always `goals(root)`; `proof_data` is always `load_dataset(root).proofs`).
- `@_scoped` bounds the cache lifetime to **one outermost call** via a module-level depth guard
  (`_SCOPE_DEPTH`): re-entering at depth 0 clears every cache on entry and exit, so each top-level
  generation re-reads the working tree; nested calls run at depth > 0 and hit the warm cache.
- `main()` is `@_scoped`, so a full `--write` / `--write-if-stale` / `--check` shares one warm
  cache across all seven renderers (each record parsed once, each directory walked once).

## Correctness contract

- **Byte-identical output.** The artifacts are unchanged. Guards: the SPEC-023-A golden tests
  (exact scores, credit, attribution counts) stay green; an equivalence check confirms the
  directory-scoped attribution equals the per-file output on the live git history.
- **No stale memo across a corpus change.** Because the cache lifetime is one outermost call, any
  recomputation after an in-process corpus mutation must enter a fresh top-level scope, which
  re-reads the tree. This holds for: the one-shot CLI; the workflow's rebase-and-regen push retry
  (a fresh `main` invocation); a direct library call to a `@_scoped` loader (it self-scopes); and
  unit tests that mutate then recompute (e.g. registering a benchmark suite — ADR-092 — then
  recomputing `base_stats`).
- **`reset_caches()`** drops every loader cache; it is the depth-0 entry/exit action and is
  available for explicit use (e.g. test fixtures).

## Performance (live corpus, 2026-06-25: ~4,000 proofs / ~1,200 runs / ~14k commits)

| Operation | Before | After |
|---|---:|---:|
| One add-author `git log` walk | ~86 s (≈4k pathspecs) | ~0.7 s (1 directory pathspec) |
| `load_dataset` (parse ~9k records) | ~14 s, run ~4–9× | ~14 s, run **once** |
| **Full `--write-if-stale` regen** | **~64 min** | **~10 s** |

This restores the push-on-merge model (ADR-036/082): a regen that finishes in seconds keeps
`docs/metrics/leaderboard-ui.json` `generated_at` within minutes of `main` HEAD even under a
sustained ≥1-merge/2-min flood, satisfying the issue #6317 acceptance criteria for refresh latency
and per-refresh recompute time.

## Out of scope (deferred — issue #6317 defence-in-depth)

Not addressed here; tracked for a follow-up ADR: a dedicated serialized refresh worker / single-
flight queue, a self-rescheduling backstop to replace the GitHub `*/15` cron (throttled to ~1×/hr),
and a `timeout-minutes` + alert so a starved pipeline fails loudly. The fast regen makes the board
keep pace under normal load; these harden the tail.

## Tests

`tools/leaderboard/tests/test_generate.py`:

- `test_git_add_authors_walks_one_directory_not_per_file` — attribution result correct **and** a
  single `library/index` pathspec, independent of proof count.
- `test_goal_add_authors_walks_one_directory_not_per_goal` — same for the `goals` walk.
- `test_main_walks_git_attribution_once_across_renderers` — a full `--write` walks each directory
  exactly once.
- `test_generation_parses_each_record_once` — a full `--write` parses each source record once, not
  once per renderer.
- `test_separate_top_level_calls_re_read_the_tree` — a corpus change between two in-process
  generations is always seen (no stale memo), via both `base_stats` and the CLI entry point.
- Existing SPEC-023-A golden tests — unchanged output.
