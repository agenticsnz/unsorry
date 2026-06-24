The honest-difficulty backfill now also covers ohdearquant's `mac-158f`
deterministic Python/sympy templates, not only seedkit
([ADR-088](docs/adrs/ADR-088-Extend-Difficulty-Backfill-To-Mac158f.md)). ADR-087
left a cross-prover inconsistency — two identical-triviality `gzmod` goals could
sit at difficulty `1` (proved by seedkit) versus `3` (proved by mac-158f),
differing only by who proved them. The attribution sweep's difficulty pass now
identifies *any* deterministic-template fixture (`index_is_template_fixture` =
seedkit ∪ mac-158f) and corrects ~493 further `mac-158f` goal records
(`gzmod`/`sum`/`dvd`/`gbinom`/`sq`/…) from the inflated 3–5 self-tag to the honest
`1`. mac-158f provenance is unchanged (already `provider≜python; model≜sympy` via
the ADR-079 rule); `solver≜` credit is unchanged; the sweep stays idempotent and
self-healing. ohdearquant's difficulty-weighted leaderboard points drop to reflect
honest difficulty — a deliberate, ADR-088-approved standings correction.
