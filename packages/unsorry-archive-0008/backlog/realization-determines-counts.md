# realization-determines-counts

The face/edge/vertex counts of an abstract regular polyhedron are determined by (p,q): two realizations with the same (p,q) have equal V,E,F.

- **Source:** Freek #50 combinatorial classification, Track-1 completion (ADR-031; #400 plan Phase 1).
- **Reference:** The face/edge/vertex counts of an abstract regular polyhedron are determined by (p,q): two realizations with the same (p,q) have equal V,E,F. Not in mathlib (no abstract-regular-polyhedron theory).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 5
- **Decomposition sketch:** the linear system (2 handshakes + Euler) has a unique solution given p,q≥3 with a realization; derive E then V,F. A decompose→recompose candidate.
- **Relationship to #365:** completes the Track-1 *combinatorial* classification of the Platonic solids. Geometric Freek #50 remains Track-2 (mathlib-substrate-gated).
