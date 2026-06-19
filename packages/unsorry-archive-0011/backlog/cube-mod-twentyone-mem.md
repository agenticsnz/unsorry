# cube-mod-twentyone-mem

Every cube is congruent to one of {0,1,6,7,8,13,14,15,20} modulo 21.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every cube is congruent to one of {0,1,6,7,8,13,14,15,20} modulo 21. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod reduces n^3 % 21 to a function of n % 21; decide over the 21 cases. Verified to build (lake env lean).
