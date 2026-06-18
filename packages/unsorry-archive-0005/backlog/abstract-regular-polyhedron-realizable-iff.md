# abstract-regular-polyhedron-realizable-iff

The Track-1 **existence-biconditional**: for p, q ≥ 3, the pair (p,q) is a Platonic Schläfli pair {(3,3),(3,4),(4,3),(3,5),(5,3)} **iff** it is realizable by an abstract regular polyhedron (∃ V E F > 0 with p·F=2E, q·V=2E, V+F=E+2).

- **Source:** The capstone of Freek #50's combinatorial classification (ADR-031, Track 1) — the labelled combinatorial/Euler form, explicitly NOT the geometric #50.
- **Reference:** ⟹ is the existence direction (`platonic-pairs-realizable`); ⟸ is the proved classification (`abstract-regular-polyhedron-classification`). Composing them gives the biconditional. mathlib has neither.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** `constructor`. Forward (∈ five → realizable): `fin_cases` + the five witnesses (reuse `platonic-pairs-realizable`). Backward (realizable → ∈ five): `rintro ⟨V,E,F,…⟩` then apply the library lemma `abstract_regular_polyhedron_classification`. A decompose→recompose target reusing two library proofs.
- **Relationship to #365:** completes the Track-1 combinatorial biconditional. Geometric Freek #50 stays unclaimed (Track 2, mathlib-substrate-gated).
