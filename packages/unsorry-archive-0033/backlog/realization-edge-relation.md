# realization-edge-relation

For an abstract regular polyhedron, the handshakes + Euler give 2E(p+q) = pq(E+2).

- **Source:** Freek #50 combinatorial classification, Track-1 completion (ADR-031; #400 plan Phase 1).
- **Reference:** For an abstract regular polyhedron, the handshakes + Euler give 2E(p+q) = pq(E+2). Not in mathlib (no abstract-regular-polyhedron theory).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** rw the pq(E+2)=pq(V+F) via Euler, then nlinarith [handshakes]. Fully verified to build.
- **Relationship to #365:** completes the Track-1 *combinatorial* classification of the Platonic solids. Geometric Freek #50 remains Track-2 (mathlib-substrate-gated).
