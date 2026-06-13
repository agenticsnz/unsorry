# abstract-regular-polyhedron-classification

For an abstract regular polyhedron — V vertices, E edges, F faces that are p-gons, vertices of degree q — with the two handshakes p·F = 2E and q·V = 2E and Euler's relation V + F = E + 2, the pair (p, q) is one of the five Platonic Schläfli pairs {(3,3),(3,4),(4,3),(3,5),(5,3)}. The classification (⟹) half of Freek #50 in combinatorial/Euler form.

- **Source:** Freek 100 (#50), combinatorial form (ADR-031 / SPEC-031-A, Track 1)
- **Reference:** The classification half of 'there are exactly five Platonic solids', reusing the proved `platonic_schlafli_pairs` as keystone (Euler + handshake ⟹ 1/p+1/q > 1/2 ⟹ the five pairs). Coxeter, Regular Polytopes, Ch. 1. NOT the geometric Freek #50 (that is Track 2, gated on a mathlib polytope face lattice + Euler–Poincaré).
- **Absence:** no-local-match — a novel composite statement; the keystone `platonic_schlafli_pairs` lives in this library, not mathlib (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 3
- **Decomposition sketch:** L1 from the two handshakes (with 0<E from p≥3, F>0) and Euler derive over ℚ that 1/p + 1/q = 1/2 + 1/E > 1/2. L2 apply the proved `platonic_schlafli_pairs` (dependency reuse, ADR-014). NON-VACUOUS: the five solids (e.g. tetra V4 E6 F4) satisfy the hypotheses. This is the ⟹ direction only — existence (the five witnesses) is a separate target.
