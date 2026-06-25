# ADR-092: Segregated Benchmark Track — Verified pass@k over Registered Suites

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-092 |
| **Initiative** | Benchmark unsorry against known Lean suites (#5643) |
| **Proposed By** | unsorry maintainers (directed by Chris Barlow, #5643) |
| **Date** | 2026-06-24 |
| **Status** | Accepted |

## Context

Issue #5643 asked what it would take to benchmark unsorry against known benchmarks
(SWE-bench Lite; historically hard, recently-solved problems). The research
([docs/proposals/benchmark-track.md](../proposals/benchmark-track.md)) found two
answers on opposite sides of the founding soundness line:

- **SWE-bench Lite is out of scope *by design*.** Its oracle is a unit-test suite —
  the "gameable oracle" the founding plan ranked #3-of-9 and rejected, and which
  [ADR-080](ADR-080-Platform-Generalisation-And-Domain-Neutrality.md) clause 3
  explicitly bars from the trustless commons. unsorry emits kernel-verified Lean
  proofs, not Python patches.
- **Lean/math suites fit natively.** A benchmark item (PutnamBench, miniF2F,
  CombiBench, curated historically-hard statements) *is already* what unsorry eats —
  a Lean statement ending in `sorry`.

The machinery to admit and credit such suites is now ratified and built:
[ADR-081](ADR-081-Problem-Admission-And-Intake-Pipeline.md) intake +
`skeleton-validate` (SPEC-081-A), [ADR-078](ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md)
registered targets + credited/glue, and [ADR-080](ADR-080-Platform-Generalisation-And-Domain-Neutrality.md)
domain admission (`lean-math` at `tier: VERIFIED`, SPEC-080-A). What remains is the
*benchmark-track policy*: how a suite is ingested, **scored**, and **surfaced**
without distorting the organic leaderboard or inventing a parallel scheme.

One scope boundary matters: the only prior written benchmark intent (Phase-3
roadmap Thread G) benchmarks the **AISP coordination notation**. This ADR benchmarks
the **proof-solving swarm itself** — a distinct, previously-unplanned capability.

## WH(Y) Decision Statement

**In the context of** ratified ADR-078/080/081, the built `skeleton-validate` intake
gate, the `lean-math` VERIFIED domain, and an organic difficulty-weighted leaderboard
that must not be polluted,

**facing** the choice of how to benchmark the solver — and how to score and surface it
— without distorting organic standings or minting a bespoke scoring scheme,

**we decided for** a **segregated benchmark track**: each external Lean suite is
imported as **one ADR-081 skeleton package registered as one ADR-078 target** under
`targets/<suite>/` (a synthetic `top` sentinel that is `glue` and roots the DAG; each
benchmark theorem a **leaf obligation**, individually claimable and credited),
admitted by `skeleton-validate`, with per-obligation **credited/glue** classification
by the ADR-078 full battery. Benchmark discharges carry a `cohort:benchmark` tag and
are scored as **verified pass@k** — every counted pass is a kernel-verified Gate A
merge (ADR-006/048) — reported on a **separate surface** and **excluded** from the
organic `community-stats` headline counts and the difficulty-weighted column,

**and neglected** (a) SWE-bench Lite / any test-oracle suite — ADR-080 excludes them
from the commons; cite SWE-bench only as the deliberately-excluded contrast; (b) a
lightweight per-goal `bench≜` tag *without* the skeleton-package/registry — it forgoes
the farm-proof curated-supplier provenance and the credited/glue floor; (c) summing
benchmark credit into the organic board — it would distort standings (the ADR-088
lesson); (d) a bespoke benchmark scoring scheme — conform to the existing
credited-obligation canon (ADR-035/078/088), not a parallel one,

**to achieve** an honest, farm-proof benchmark of the proof-solving swarm —
"**verified pass@k, zero false positives**" — that a contributor can drive one goal at
a time (`./swarm/run.sh --goal <id>`) and that the guild surfaces as *intent*, without
changing what the organic leaderboard measures,

**accepting that** benchmark `difficulty` self-tags stay advisory (not gate-enforced,
ADR-035); that per-suite re-elaboration under the pinned mathlib rev has a **quarantine
rate** (non-elaborating statements are reported, never imported); and that "0 false
positives" is relative to the *imported statements*, so a false-statement filter and a
contamination/memorisation disclosure are mandatory when reporting.

## Decision detail

1. **One suite = one `targets/<suite>/` skeleton package = one ADR-078 target.** The
   `top` is a synthetic suite sentinel (`credit≜glue`); each theorem is a leaf
   obligation. Goals live at top-level `goals/<id>.{aisp,lean}`; the registry copy
   `targets/<suite>/obligations/<sha>.lean` is tied to the queue copy by
   `statement_sha` (enforced at `skeleton-validate`).
2. **Cohort segregation.** Benchmark discharges are tagged `cohort:benchmark`,
   excluded from the organic `_score`/`community-stats` headline counts and the
   difficulty-weighted column, and rendered on their own board surface. Conforms to
   the SPEC-078-A dual-track stance; the organic rank key is unchanged.
3. **Metric — verified pass@k.** Scored over Gate-A-merged discharges
   (`library/index`), using the unbiased estimator over a fixed per-goal sample
   budget the track documents. Every reported figure is paired with the literal
   **"0 false positives (kernel-verified)"** — a claim test-based eval and
   self-reported pass@k cannot make.
4. **Intent channel.** `docs/metrics/registered-targets.json` (SPEC-092-A) publishes
   the suites + per-goal `run_snippet`; the unsorry-guild goals page consumes it. A
   contributor copies the **kebab slug** and runs `./swarm/run.sh --goal <id>`.
5. **Conformance, no new trust surface.** Admission via `skeleton-validate` (ADR-081);
   registration + credited/glue via ADR-078; `lean-math` VERIFIED via ADR-080. The only
   trust surfaces are `targets/**`, `tools/intake/`, `tools/governance/`,
   `docs/governance/`, `tools/leaderboard/` — already CODEOWNERS-gated.
6. **Anti-gaming is structural.** ADR-011 statement-binding defeats "restate as `True`";
   the ADR-035/078 triviality battery makes one-tactic-closable leaves `glue` (earn
   zero); `skeleton-validate` rejects ill-formed packages at the door. The
   triviality-rejection rate is itself reported as a benchmark signal, not hidden.

## Consequences

- **Positive.** An honest, farm-proof benchmark of the solver that reuses the ratified
  intake/credit/domain machinery end-to-end; the organic board is protected; the
  contributor flow already works (`run.sh --goal <id>`, M6).
- **Cost.** A `registered-targets.json` generator + cohort-segregation filter in
  `tools/leaderboard` (SPEC-092-A); a benchmark importer (`tools/intake/import_benchmark.py`,
  the ADR-081 path) running the four sourcing gates and the ≤50-obligation batch cap;
  per-suite license/provenance recording.
- **Residue.** mathlib-pin quarantine rate (reported, never silently dropped); the
  statement-fidelity caveat (a wrong-but-agreed formalisation passes Gate A — the
  false-statement filter is mandatory); benchmark contamination/memorisation disclosed
  when reporting; provenance (which model) is corroborated (ADR-023/037), not
  kernel-enforced — prefer whole-swarm aggregate pass@k, or per-model with the caveat.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Benchmark track — research & plan | Proposal | docs/proposals/benchmark-track.md |
| REF-2 | Sponsor-Registered Targets & Obligation-Discharge Credit | Decision | ADR-078-…md |
| REF-3 | Platform Generalisation & the Gating Invariant | Decision | ADR-080-…md |
| REF-4 | Problem Admission & the Skeleton Intake Pipeline | Decision | ADR-081-…md |
| REF-5 | skeleton-validate intake validator | Spec | specs/SPEC-081-A-…md |
| REF-6 | Domain-Admission Registry | Spec | specs/SPEC-080-A-…md |
| REF-7 | Non-Trivial Theorem Enforcement (the triviality battery) | Decision | ADR-035-…md |
| REF-8 | Honest-Difficulty Backfill (the don't-distort-the-board lesson) | Decision | ADR-088-…md |
| REF-9 | Statement-Binding Gate (anti-restatement) | Decision | ADR-011-…md |
| REF-10 | registered-targets.json contract + pass@k + segregation | Spec | specs/SPEC-092-A-Benchmark-Track.md |
| REF-11 | Issue: Benchmark unsorry | Discussion | #5643 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers (#5643) | 2026-06-24 |
| Accepted | Chris Barlow (founder, #5643) | 2026-06-24 |
