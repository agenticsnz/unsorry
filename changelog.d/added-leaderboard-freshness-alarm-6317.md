The leaderboard refresh now has a **freshness alarm** so the published board can
never go silently stale ([#6317](https://github.com/agenticsnz/unsorry/issues/6317),
[ADR-098](docs/adrs/ADR-098-Leaderboard-Freshness-Alarm.md)). On every run the
workflow checks the published `leaderboard-ui.json` `generated_at` against the
latest board-source commit and, past a 30-min lag, emits a visible `::error::`
and fails the run — surfacing a lost push race or starved pipeline instead of
serving hours-old standings. The refresh job also gains a `timeout-minutes: 15`
guard so a hung run fails loudly rather than producing nothing. Backed by a new,
unit-tested `tools.leaderboard.freshness` gate.
