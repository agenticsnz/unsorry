# Themes and the difficulty mandate

ADR-060 / #400: **harder problems, many more of them.** Difficulty (0–5) is
self-tagged and gate-unenforced, so the supply is only as hard as the sourcer
makes it. Today most shipped goals sit at difficulty 1–2 — that is the gap to
close. Source the families below **in parallel** (ADR-031/043).

## What makes a goal hard *and* admissible

The triviality battery (gate 3) is `rfl, trivial, decide, norm_num, omega, simp,
simp_all, aesop, ring, linarith, tauto`. It **deliberately omits** `native_decide`
and, crucially, `nlinarith / positivity / field_simp / gcongr` (ADR-035). So:

- A goal closable only by `nlinarith`/`positivity`/`gcongr` **survives** the
  battery — these are a reliable supply of genuinely harder, admissible targets.
- But survival is not virtue: if *you* can close it in one `nlinarith`, it is not
  hard. Drop it. The bar is "no short one-tactic proof," judged by you.

## Hard families to mine

- **Multivariate SOS / polynomial & field inequalities** — AM–GM variants,
  Cauchy–Schwarz instances, Schur-like inequalities, rational-function identities.
  (`sos-inequalities`, `continued-fraction-pell`, `partition-genfun` are existing
  high-difficulty themes.)
- **Olympiad / competition** — PutnamBench, miniF2F, Freek-100, IMO-style number
  theory and combinatorics. `docs/phase2-targets.md` lists high-absence-confidence
  PutnamBench/CombiBench candidates. Expect higher gate-2/gate-4 drop rates — a
  signal, not a failure.
- **Analytic / number theory** — partition identities, generating-function
  coefficient extraction, Dirichlet-style sums, residue arguments.
- **Decomposable structure** — prefer goals carrying ≥1 decomposition edge
  (ADR-009: split a hard parent into ≤8 sub-lemmas, ≤3 depth, as a DAG). Each
  sub-lemma re-enters the queue as a fresh open goal — this multiplies *depth* and
  *volume* at once, without padding.

## Freek-#50 substrate (Phase 2) — the honest ceiling

The real geometric Freek #50 needs Euler's polyhedron formula, which mathlib
lacks. **Provable now** (source these): planar-graph Euler characteristic, tree
edge counts, cycle-space rank, f-vector relations for concrete polytopes —
the graph-theory layer toward Euler, building on existing mathlib
(`SimpleGraph.sum_degrees_eq_twice_card_edges`, etc.).

**Substrate-blocked** (do NOT source — gate 2 fails them at the pinned mathlib):
the polytope face lattice, Euler–Poincaré, the ℝ³ regular-polyhedron biconditional.
ADR-031 estimates **fewer than 50** genuine Phase-2 targets exist; the shortfall is
the real signal — it is exactly the mathlib gap a human upstreaming push (ADR-020)
must fill. Source the provable layer honestly and report where the substrate runs
out, rather than padding with statements that cannot type-check.

## Volume without dilution

- Keep the two-tier pipeline running: stage candidates cheaply in
  `backlog/candidates/<theme>.md` (gates 1+3 only, no build) to keep the backlog
  **≥200 ahead**; promote ~100/cycle in ≤50-goal waves.
- The throughput bottleneck for "way more" is **CI capacity** (45-min
  `gate-a-prepare`), not generation — batch tightly to ≤50/PR and surface the
  constraint rather than flooding the queue.

## What you must not do to "raise the bar"

Do **not** add `nlinarith`/`positivity` to the triviality battery to reclassify
easy goals as hard — that supersedes the explicit ADR-035 design choice and would
reject legitimately-hard goals. If the bar should move, it is an ADR decision, not
a skill or battery edit.
