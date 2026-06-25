The leaderboard regen no longer stalls the board for hours under a merge flood
([#6317](https://github.com/agenticsnz/unsorry/issues/6317),
[ADR-097](docs/adrs/ADR-097-Incremental-Leaderboard-Regen.md)). A single
`tools.leaderboard` recompute over the live corpus dropped from **~64 min to
~10 s** — restoring the push-on-merge model so `docs/metrics/leaderboard-ui.json`
tracks `main` within minutes instead of going hours stale. Two fixes, both
producing byte-identical artifacts: git add-author attribution now walks the
`library/index` / `goals` **directory** once (~0.7 s) instead of passing one
pathspec per record (~86 s, O(history × corpus)); and the corpus loaders are
memoised for the lifetime of one generation, so each record is parsed once and
each attribution walked once across all renderers rather than ~4–9 times.
