# SPEC-092-A: Benchmark Track — registered-targets.json, pass@k, and Cohort Segregation

Implements: [ADR-092](../ADR-092-Segregated-Benchmark-Track.md) · Status: Accepted · Updated: 2026-06-24 · Builds on [SPEC-078-A](SPEC-078-A-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md), [SPEC-081-A](SPEC-081-A-Skeleton-Validate.md), [SPEC-080-A](SPEC-080-A-Domain-Admission-Registry.md)

This SPEC fixes the *how* of ADR-092: the machine-readable intent surface the guild
reads, the verified-pass@k computation, and the cohort-segregation rule that keeps
benchmark credit off the organic board.

## 1. The published index — `docs/metrics/registered-targets.json`

A new generator pass in `tools/leaderboard/generate.py` (a CODEOWNERS surface) reads
`targets/**` and emits, deterministically (`json.dumps(..., sort_keys=True)`, no
timestamps so `--check` does not churn), added to the existing artifact tuple so
`--check` / `--write` / `--write-if-stale` cover it on the ADR-082/036 post-merge
cadence:

```jsonc
{
  "schema_version": 1,
  "suites": [
    {
      "id": "putnambench",
      "domain": "lean-math",
      "supplier": "<vetted-id>",
      "mathlib_pin": "<rev>",
      "license": "Apache-2.0",
      "cohort": "benchmark",
      "credited": 412, "glue": 18, "proved": 37,
      "pass_at": { "k1": 0.06, "k8": 0.14 },          // verified pass@k, kernel-checked
      "goals": [
        {
          "id": "putnambench-1988-b2",
          "difficulty": 4,
          "status": "open",               // open | proved (from library/index presence)
          "credit": "credited",           // credited | glue (from skeleton, check 7)
          "run_snippet": "./swarm/run.sh --goal putnambench-1988-b2"
        }
      ]
    }
  ]
}
```

- `status` per goal is derived from `library/index/<sha>.aisp` presence (mirror
  `tools/sourcing/targets_board.py` `_proved`), not stored.
- `credit` is read from the package `skeleton.aisp` (the `skeleton-validate` check-7
  classification).
- `run_snippet` is the copy-paste line the guild surfaces. The cross-repo contract is
  `schema_version` — bump it on any field rename; the guild treats a rename as breaking.

## 2. Verified pass@k

Every counted "pass" is a Gate-A-merged discharge (ADR-006/048): kernel re-verified,
axiom-audited, statement-bound (ADR-011). pass@k uses the unbiased estimator

```
pass@k = E[ 1 − C(n − c, k) / C(n, k) ]
```

over `n ≥ k` independent attempts per goal under a **fixed, documented sample budget**,
`c` = kernel-accepted attempts. The track records each attempt as a distinct budgeted
proof-run so `n`/`c` are well-defined (today's `proof-runs/` `attempts` integer is
insufficient — the importer/run path must log per-attempt). Every reported number is
paired with the literal **"0 false positives (kernel-verified)"**.

Two disclosures are mandatory when reporting:
1. the **triviality-rejection rate** (leaves filtered as `glue` before the swarm
   attempts them bias the measured set harder — report it, do not hide it);
2. **contamination/memorisation** (public benchmark solutions are likely in training
   data; high pass@k may reflect recall).

## 3. Cohort segregation (the load-bearing invariant)

The leaderboard credit pass MUST exclude `cohort:benchmark` discharges from:
- the organic `community-stats.json` headline counts,
- the organic difficulty-weighted column and `_score`,
- the organic rank key `(-credited_proofs, -difficulty_points, name)` (unchanged in
  shape; benchmark proofs simply do not feed it).

Benchmark standings render on their own surface (the `registered-targets.json` panel /
a per-suite board). This conforms to the SPEC-078-A dual-track stance and the ADR-088
"do not distort the board" lesson.

## 4. Acceptance criteria

1. `test_registered_targets_json_shape` — a fixture `targets/<suite>/` produces the
   schema above; deterministic (`--check` after `--write` is a no-op).
2. `test_status_from_library_index` — a goal with a `library/index/<sha>.aisp` shows
   `status: proved`; without, `open`.
3. `test_credit_from_skeleton` — `credited`/`glue` is read from the package skeleton.
4. `test_cohort_excluded_from_organic` — adding a benchmark suite + discharges leaves
   the organic `community-stats.json` headline counts **unchanged** (the segregation
   invariant; the most important test).
5. `test_pass_at_k_estimator` — the unbiased estimator over fixture run records matches
   hand-computed values for small `n,c,k`; `pass@k = 0` when `c = 0`, `1` when `c = n`.
6. `test_run_snippet_is_kebab_slug` — `run_snippet` is `./swarm/run.sh --goal <id>`
   with the goal's kebab id.

## 5. Out of scope (for this SPEC)
- The importer that *produces* `targets/**` (ADR-081 path, `tools/intake/import_benchmark.py`).
- The unsorry-guild goals-page UI (separate repo; consumes this contract).
- Per-model attribution beyond the ADR-023/037 corroboration already in place.
