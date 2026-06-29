# platonic-pairs-realizable

Each of the five Platonic Schläfli pairs {(3,3),(3,4),(4,3),(3,5),(5,3)} is **realizable** by an abstract regular polyhedron: there exist V, E, F (>0) satisfying the two handshakes p·F=2E, q·V=2E and Euler V+F=E+2.

- **Source:** The **existence (⟸) direction** of Freek #50's combinatorial classification (ADR-031, Track 1). Complements the proved classification (⟹) `abstract-regular-polyhedron-classification`; together they are the Track-1 existence-biconditional.
- **Reference:** witnesses — tetra (3,3)→(4,6,4), octa (3,4)→(6,12,8), cube (4,3)→(8,12,6), icosa (3,5)→(12,30,20), dodeca (5,3)→(20,30,12). mathlib has no abstract-regular-polyhedron realizability lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — the existential over ℕ hides the witnesses from the one-shot battery (`decide` cannot enumerate ℕ³).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** `intro pq hpq; fin_cases hpq` → five concrete goals; each `exact ⟨V, E, F, by norm_num⟩` with the witness above. Verified to build (lake env lean).
- **Relationship to #365:** the existence half of the Track-1 combinatorial classification of the Platonic solids — NOT the geometric Freek #50 (Track 2, gated on a mathlib polytope face lattice + Euler–Poincaré).
