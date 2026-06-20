# SPEC-078-A: Structural (Package-Graph) Scoring

Implements: [ADR-078](../ADR-078-Structural-Package-Graph-Non-Triviality-And-Scoring.md) · Status: Draft · Updated: 2026-06-20

> **DRAFT** — coefficients are placeholders to calibrate on the Lion pilot. Build
> after ADR-078 is ratified.

## What this adds

A scorer that weights a discharged obligation by its **position in its curated
package's decomposition DAG** (depth + fan-in) rather than by a standalone tactic
battery — the machine form of ADR-078's "non-trivial = something architected depends
on it."

## Data sources (all already present)

- **Edges:** `decompositions/<parent>.<agent>.aisp` (`parent` + `sub` ids) — walked
  today by `tools/archive/apply.py:decomposition_components`.
- **Discharged markers:** `library/index/*.aisp` (a goal is discharged iff it has an
  index entry).
- **Curated-target membership:** the package manifest (SPEC-080-A) — only obligations
  belonging to an admitted curated package earn structural weight.

## Scoring

For a discharged obligation `g` in curated package `P`:
- `depth(g)` = longest path from `P.top` down to `g` in the DAG.
- `fan_in(g)` = number of *discharged* obligations `g` directly rests on (its subs).
- `weight(g) = difficulty(g) × (1 + α·depth(g) + β·fan_in(g)) × pad_discount(g)`

where `α`, `β` are tunable (default placeholders α=0.5, β=0.5, **to calibrate on
Lion**), and `pad_discount(g) ∈ (0,1]` penalises over-decomposition padding
(ADR-078): a pass-through node (single statement-identical sub) or a depth-inflating
chain is discounted toward 0. A standalone atom — no package, no dependents — has
depth 0, fan-in 0, and earns ≈ its base difficulty only (the farming floor).

**Farm-proofing rests on curation, not the formula:** structural weight is counted
*only* for obligations inside an admitted curated package (SPEC-079-A / SPEC-080-A).
Self-minted graphs do not score, so depth cannot be manufactured.

## Where it plugs in

`tools/leaderboard` — structural weight augments/replaces the standalone difficulty
input in the existing score (`difficulty×100 + credited_proofs×25 + dispatch×100`,
the leaderboard scorer). Composition with dispatch credit is preserved; the board
gains a per-package "contribution to a real proof" view.

## Reuse
`decomposition_components` + the edge walk (shared with the archive binding-defer
check); the goal-record/index accessors in `tools.leaderboard.generate`.

## Tests (`tools/leaderboard/tests/` or `tools/intake/tests/`)
- depth/fan-in computed correctly on a fixture DAG (diamond, chain, fan-out);
- standalone atom → ≈ base difficulty (farming floor);
- pass-through / depth-inflation node → discounted;
- obligation outside a curated package → no structural weight;
- score is monotonic in depth and fan-in, all else equal.

## Open
- Calibrate α, β, and `pad_discount` on the real Lion graph before promoting.
- Migration of the existing leaderboard (recompute vs. forward-only).
