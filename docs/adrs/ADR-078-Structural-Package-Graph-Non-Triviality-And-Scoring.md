# ADR-078: Structural (Package-Graph) Non-Triviality and Scoring

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-078 |
| **Initiative** | unsorry — from atomic goals to architected-package discharge |
| **Proposed By** | Leo (Chief of Staff to Haiyang "Ocean" Li, khive AI); drafted with unsorry maintainers |
| **Date** | 2026-06-20 |
| **Status** | Draft |

> **This is a DRAFT for discussion** — something concrete to argue with, not an
> accepted decision. The structural-hardness reframe is Leo's; the curated-target
> trust model, the score-vs-merge separation, and the over-decomposition
> normalization are refinements added in review.

## Context

unsorry decides whether a goal is "non-trivial" with a tactic **battery** (ADR-035):
a probe runs a fixed set (`simp`, `aesop`, `decide`, `ring`, …) under a full
`import Mathlib`, which correctly answers *"is this already in the library under
another name?"* for an **atomic** goal. Two structural facts limit it:

1. **It is advisory, not a gate.** `triviality.yml` is non-blocking by design
   (*"always exits 0 — do NOT add it to branch-protection's required checks"*), and
   ADR-035 records the rejected "blocking-from-day-one" alternative. So a trivial
   goal sourced outside the pipeline still merges. In practice this is what
   high-volume template runs exploited: goals closed by `ring`/`decide` — squarely
   inside the battery — would have been dropped by a *hard* gate but merged because
   the probe binds at sourcing time only. Granularity compounds it: when goals are
   atomic, one genuinely hard result can be restated many ways and each restatement
   is its own merge.

2. **Any fixed battery defines a farmable complement.** We deliberately exclude
   `nlinarith`, `positivity`, `field_simp`, `gcongr` so real inequalities survive —
   but a generator aimed at exactly the goals those tactics close in one shot passes
   deterministically. The honor rule (*"if one `nlinarith` closes it, drop it"*)
   carries the load there, and honor rules do not survive contact with automation.
   Estimating the difficulty of an arbitrary closed statement is about as hard as
   proving it, so a per-goal hardness oracle is a long road with no clear end.

The deeper point: **a better battery cannot fix this, because the problem is not the
battery.** Triviality is being treated as an intrinsic property of a goal, and any
intrinsic, tactic-defined notion is farmable at its boundary.

## WH(Y) Decision Statement

**In the context of** an open, untrusted, automated contributor base where goals can
be minted freely and "hardness" is judged by a fixed tactic battery,
**facing** the choice between (a) a smarter/larger battery, (b) a per-goal hardness
oracle, and (c) redefining non-triviality structurally,
**we decided for** **structural non-triviality**: a goal's weight is its position in
the dependency graph of a **curated, externally-authored proof package** — its depth
and fan-in over the decomposition DAG — not the output of a standalone battery. A
lemma is non-trivial when **something larger that someone deliberately architected
depends on it**,
**and neglected** a better battery (its complement is still farmable) and a hardness
oracle (≈ as hard as proving the goal, no clear end),
**to achieve** a scoring/admission model that is (i) **not farmable** — you cannot
manufacture the sub-lemmas of a theorem you did not architect — and (ii)
**valuable** — discharging an obligation produces a verified artifact, not points,
**accepting that** it makes goal supply **dependent on skeleton suppliers** (the
engine no longer mints its own work), and that the anti-farming guarantee holds
**only for curated targets** — self-submitted packages can inflate depth, so a trust
layer on *what becomes a scored target* is load-bearing.

## Decision detail

1. **Score by structure, over the decomposition DAG we already track.**
   `decompositions/*.aisp` carry `parent` + `sub` edges (machine-readable), and
   `tools/archive/apply.py:decomposition_components` + the proof-graph visualiser
   already traverse them. Score a discharged obligation by its **depth** (distance
   to the package root) and **fan-in** (how many discharged obligations it rests on)
   within its package. A standalone atom with no dependents scores ≈ 0 — which
   removes the farming *incentive* at the root, tactic-independently.

2. **Curated targets only (the anti-self-farming layer).** Structural depth is
   farm-proof *only when the skeleton is externally authored.* A contributor
   submitting their own package could over-decompose to inflate depth. So a package
   scores only once **admitted as a curated target** (e.g. supplied by a vetted
   skeleton owner — the Lion kernel, a mathematician's formalization-in-progress —
   under a defined trust/review step). Define this admission mechanism explicitly;
   it is where the model lives or dies.

3. **Separate "what counts" from "what merges."** Structural scoring governs
   *credit*. It does not, by itself, stop a zero-value atom from *merging* and
   cluttering the library. Decide separately whether to also promote the triviality
   probe to a **blocking merge bar** for non-package goals (ADR-035's deferred
   option), now that scoring removes the incentive to submit them.

4. **Over-decomposition normalization.** Even within a curated target, guard against
   inflating score by padding a tree with trivial intermediate lemmas (e.g.
   discount degenerate fan-in / near-pass-through nodes). Specify the normalization.

## Consequences — what actually changes

- **The unit of work shifts from atom → obligation-in-a-skeleton.** Goals stop being
  self-minted trivia and arrive as the open `sorry`s of architected packages.
- **The board measures contribution to a real proof, not volume.** This composes
  with the existing leaderboard difficulty + dispatch credit (ADR — leaderboard
  scoring); structural weight replaces/augments the standalone difficulty input.
- **The platform becomes a product, not a competition harness.** Untrusted
  distributed contributors + kernel re-verification + statement-hash dedup +
  provenance is exactly the machine to crowd-source the discharge of a large
  `sorry`-skeleton. Math becomes **one** source of skeletons, not the scope —
  verified software (Lion), protocols, and crypto are equally valid targets.
- **New dependency: skeleton supply.** Self-sufficiency (mint your own goals) is
  traded for an external pipeline of curated targets. Ocean's offer to open-source
  the full Lion proof and bring in mathematicians with their own skeletons
  bootstraps this supply side.

## Open questions (to resolve before Accepted)

1. **Curated-target admission.** Who/what vets a package as a scored target, and how
   is that recorded auditably? (Trust tiers, ADR-054, are the natural home.)
2. **Cross-prover / domain reach.** Lion is *software* verification. Is its proof in
   **Lean** (the swarm can attempt it) or Isabelle/seL4-family (it cannot, without a
   retarget)? And does the math-tuned swarm discharge *program-proof* obligations
   (refinement/Hoare-style) — Lion is the domain-transfer pilot that answers this.
3. **Exact scoring formula** (depth/fan-in weighting, normalization) and how it
   migrates the current leaderboard without rewriting history.
4. **Merge policy** for non-package atoms once they score ≈ 0 (block, or allow-but-
   uncredited?).

## Pilot

Adopt the **Lion proof** as the first curated target package: discharge its open
obligations through the existing swarm + Gate A, score by structural position, and
use the run to (a) validate cross-domain discharge and (b) calibrate the scoring
formula on a real architected graph before generalizing.
