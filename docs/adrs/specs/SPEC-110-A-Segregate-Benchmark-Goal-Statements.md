# SPEC-110-A: Benchmark Goal Statement Segregation

Implements: [ADR-110](../ADR-110-Segregate-Benchmark-Goal-Statements.md) · Status: Proposed · Updated: 2026-06-26 · Refines [SPEC-099-A](SPEC-099-A-Per-Suite-Mathlib-Pin-For-Benchmark-Ingestion.md)

Fixes the *how* of ADR-110: a benchmark obligation's swarm-visible statement is relocated
from `goals/<slug>.lean` to `benchmark-goals/<slug>.lean` at ingestion, so the repo-pin
`UnsorryGoals` build never compiles it. Scope is `tools/intake/` + `tools/leaderboard/`
(auto-merge on green gates); the swarm goal-walk, the guild fetcher, and CI board path
filters are separate follow-ups (ADR-110 Consequences).

## §1 — Importer (`tools/intake/import_benchmark.py`)

After `assemble_package` writes the top-level triple (`write_triple` → `goals/<slug>.{lean,aisp}`)
and the content-addressed package copy (`targets/<suite>/goals/<slug>.{lean,aisp}`), it
**moves** the top-level copy to `benchmark-goals/`:

- `benchmark-goals/<slug>.lean` ← `goals/<slug>.lean` (verbatim), and `goals/<slug>.lean` is removed.
- `benchmark-goals/<slug>.aisp` ← `goals/<slug>.aisp` with `⟦Λ:Artifact⟧{lean≜goals/<slug>.lean…}`
  rewritten to `lean≜benchmark-goals/<slug>.lean…`.
- The package copy under `targets/<suite>/goals/` is **not** touched — its `goals/<slug>.lean`
  artifact path is relative to the package and already correct.
- `backlog/<slug>.md` stays in `backlog/` (documentation, never built).

Invariants preserved: `statement_sha(benchmark-goals/<slug>.lean) == statement_sha(targets/<suite>/goals/<slug>.lean)`
(same bytes); idempotent re-run still skips an already-ingested slug.

## §2 — `registered-targets.json` (`tools/leaderboard/registered_targets.py`)

`_difficulty(root, goal_id)` reads the goal record from `goals/<id>.aisp` **or**
`benchmark-goals/<id>.aisp` (first that exists), so a native-pin obligation's difficulty
populates the suite card. No other field of the benchmark surface reads top-level goal files
(suite membership + counts come from `targets/<suite>/skeleton.aisp`).

## §3 — Build isolation (no change, asserted by test)

`lakefile.toml`'s `UnsorryGoals` `globs = ["goals.+"]` matches module `goals.<x>` only;
`benchmark-goals/<x>.lean` is module `benchmark_goals.<x>` and is **not** globbed. A test
asserts no `benchmark-goals/*.lean` appears in the `UnsorryGoals` build set.

## Tests (`tools/intake/tests/`, `tools/leaderboard/tests/`)

1. `assemble_package` on a benchmark fixture writes `benchmark-goals/<slug>.lean`, writes the
   package copy, and leaves **no** `goals/<slug>.lean`.
2. The relocated `.aisp` has `lean≜benchmark-goals/<slug>.lean` (artifact path rewritten).
3. Statement-hash equality between `benchmark-goals/<slug>.lean` and the package copy.
4. `_difficulty` resolves a goal whose record is only in `benchmark-goals/`.
5. Regression: organic sourcing (`gen_triples.write_triple`) is unchanged — still `goals/`.

## Verification

- `python3 -m pytest tools/intake tools/leaderboard -q` green.
- A live native-pin import (CombiBench v4.24) writes obligations to `benchmark-goals/`, none
  to `goals/`; `skeleton-validate targets/combibench-v1` admits; `registered-targets.json`
  carries the suite with correct difficulties.
- `gate-a-prepare` builds `UnsorryGoals` without the native-pin statements (they are not in
  the glob); `gate-a-benchmark` kernel-verifies the suite at v4.24.
