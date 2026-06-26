# sq-mod-twelve-mem

Every natural number's square is congruent to 0, 1, 4, or 9 modulo 12.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every natural number's square is congruent to 0, 1, 4, or 9 modulo 12. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod then decide over the 12 residue classes. Verified to build (lake env lean).
