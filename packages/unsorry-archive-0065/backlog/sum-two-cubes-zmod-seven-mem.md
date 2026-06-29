# sum-two-cubes-zmod-seven-mem

A sum of two integer cubes is never congruent to 3 or 4 modulo 7.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** A sum of two integer cubes is never congruent to 3 or 4 modulo 7. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** cast to ZMod 7, decide over ZMod 7 × ZMod 7 (cubes hit only {0,1,6}). Verified to build (lake env lean).
