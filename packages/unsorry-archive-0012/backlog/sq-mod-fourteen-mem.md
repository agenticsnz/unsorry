# sq-mod-fourteen-mem

Every perfect square is congruent to 0, 1, 2, 4, 7, 8, 9 or 11 modulo 14.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every perfect square is congruent to 0, 1, 2, 4, 7, 8, 9 or 11 modulo 14. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Reduce via Nat.pow_mod, then decide over the 14 residues of n%14 (interval_cases on n%14). Verified to build (lake env lean).
