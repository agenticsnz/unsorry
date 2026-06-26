# ADR-110: Segregate Benchmark Goal Statements From the Repo-Pin Build

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-110 |
| **Initiative** | Benchmark unsorry against known Lean suites (#5643, M8) |
| **Proposed By** | unsorry maintainers (directed by Chris Barlow, #6381) |
| **Date** | 2026-06-26 |
| **Status** | Proposed |
| **Refines** | [ADR-099](ADR-099-Per-Suite-Mathlib-Pin-For-Benchmark-Ingestion.md) |

## Context

[ADR-099](ADR-099-Per-Suite-Mathlib-Pin-For-Benchmark-Ingestion.md) lets a benchmark suite
ingest and verify at its **native** mathlib pin (e.g. v4.24) in a suite-scoped
`targets/<suite>/_verify` project, so statements that don't elaborate at the repo's v4.30
pin are recovered rather than quarantined. It segregated **verification** — the suite's
proofs are kernel-built at the suite pin by the `gate-a-benchmark` leg, never in
`UnsorryLibrary`.

It did **not** segregate **compilation of the goal statements**. The importer writes each
obligation's swarm-visible statement to top-level `goals/<slug>.lean`
(`tools/sourcing/gen_triples.py::write_triple`), and `lakefile.toml` globs **all** of
`goals.+` into the `UnsorryGoals` library, which `gate-a-prepare` builds at **v4.30**. A
goal recovered at v4.24 (e.g. `goals/brualdi-ch4-35.lean`, using `Finset.sort (· ≤ ·)` /
`List.Lex`, absent at v4.30) therefore **fails `gate-a-prepare`** — the exact #6371 build
failure, reintroduced. Since recovering a drift quarantine *means* ingesting a statement
the repo pin rejects, **every** recovered goal trips this. The gap was unexercised because
the hermetic tests stub the Lean build and every suite ingested so far (#6371) was
pre-filtered to the v4.30-compatible subset (#6381 comment, 2026-06-26).

## Decision

**A benchmark obligation's swarm-visible statement lives at top-level
`benchmark-goals/<slug>.lean`, never at `goals/<slug>.lean`.** Its Lean module is
`benchmark_goals.<slug>`, which is outside the `UnsorryGoals` glob (`goals.+`), so
`gate-a-prepare` never compiles it at the repo pin. The obligation is elaborated and
kernel-verified only at the suite pin in `targets/<suite>/_verify` (ADR-099). The
content-addressed package copy under `targets/<suite>/goals/` remains the registry source
of truth (statement-hash dedup, `skeleton-validate`).

Concretely:

1. **Importer** writes the statement triple to `benchmark-goals/` (not `goals/`); the goal
   record's `⟦Λ:Artifact⟧{lean≜…}` points at `benchmark-goals/<slug>.lean`. The package
   copy under `targets/<suite>/goals/` is unchanged (its relative `goals/<slug>.lean`
   artifact path resolves inside the package).
2. **`registered-targets.json`** reads obligation difficulty from `goals/` *or*
   `benchmark-goals/`, so the guild renders native-pin suites correctly.
3. **ADR-018 immutability** applies to `benchmark-goals/` exactly as to `goals/`
   (create-only); already-imported v4.30-compatible benchmark goals stay in `goals/`
   (immutable, and they build fine there) — only newly-ingested native-pin statements use
   `benchmark-goals/`.

### Rejected alternatives

- **(a) Keep statements in `goals/`, exclude from the glob** — Lake globs are pattern-based
  with no negation; the only way out of `goals.+` is a different module prefix.
- **(b) A pre-build CI step that relocates benchmark goals before `lake build`** — fragile,
  builds a mutated tree, leaks the coupling into `gate-a.yml`.
- **(c) Statements only inside `targets/<suite>/goals/` (no top-level copy)** — viable, but
  a top-level `benchmark-goals/` keeps the obligation swarm-discoverable with a single dir
  to scan (parallel to `goals/`) rather than walking every suite package.

## Consequences

- `gate-a-prepare` (v4.30) is green for native-pin suites; drift quarantines are recovered
  at the suite pin as ADR-099 intended.
- **Follow-ups (graceful degradation until landed, tracked under #5643):**
  - **Swarm autonomous discovery** — `swarm/agent.sh` + `swarm/sourcing.sh` goal-walks scan
    `benchmark-goals/`. Until then, native-pin goals are proved via explicit
    `./swarm/run.sh --goal <id>` (resolves through `suite_context`, no `goals/` dependency).
    (`swarm/` is a CODEOWNERS surface, ADR-019 — its own reviewed PR.)
  - **Guild statement view** — `getGoalSource` falls back `goals/` → `benchmark-goals/`
    (unsorry-guild repo).
  - **CI board triggers** — `gate-b`, `triviality`, `leaderboard`, `*-board` path filters
    add `benchmark-goals/**` so boards regenerate on benchmark-goal changes.
- No new trust surface: `benchmark-goals/` is create-only like `goals/`; verification stays
  the `gate-a-benchmark` kernel build at the suite pin (ADR-099 / ADR-048/049).
