# realization-edge-in-set

Any abstract regular polyhedron has E ∈ {6,12,30} (the only edge counts among the five Platonic solids).

- **Source:** Freek #50 combinatorial classification, Track-1 completion (ADR-031; #400 plan Phase 1).
- **Reference:** Any abstract regular polyhedron has E ∈ {6,12,30} (the only edge counts among the five Platonic solids). Not in mathlib (no abstract-regular-polyhedron theory).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** via the classification (p,q)∈five then the edge relation determines E. Concrete cases verified.
- **Relationship to #365:** completes the Track-1 *combinatorial* classification of the Platonic solids. Geometric Freek #50 remains Track-2 (mathlib-substrate-gated).
