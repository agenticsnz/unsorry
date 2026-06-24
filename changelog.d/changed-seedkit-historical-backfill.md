The attribution-relabel sweep (`tools/repo/relabel_attribution.py`) now backfills
historical seedkit fixtures to the honest labels ADR-086 made standard going
forward ([ADR-087](docs/adrs/ADR-087-Backfill-Historical-Seedkit-Records.md)). Its
provenance rules gain `template-induction-ring → lean/ring` and now process
`provider≜seedkit` records (not only the `claude`-mislabelled ones), across active
and archived index records — so seedkit's Lean `decide` / `induction; ring`
fixtures are recorded as `provider≜lean; model≜decide`/`ring` instead of a bespoke
`seedkit` engine. The sweep additionally corrects the difficulty of every
seedkit-origin goal record from the inflated 3–5 self-tag to the honest `1` a
one-tactic template earns under the sourcing rubric, identifying those goals by
their own proof provenance (no fragile goal-id prefix list). It stays idempotent
and self-healing, and `mac-158f`'s genuine Python/sympy templates and any real LLM
proof are untouched. `solver≜` credit and credited-proof counts are unchanged;
only difficulty-weighted leaderboard points move — so fixture contributors'
`difficulty_points` and score drop to reflect honest difficulty. This is a
deliberate, ADR-087-approved standings correction, not a regression.
