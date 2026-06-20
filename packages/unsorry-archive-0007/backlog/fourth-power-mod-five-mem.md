# fourth-power-mod-five-mem

Every natural number's fourth power is congruent to 0 or 1 modulo 5.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every natural number's fourth power is congruent to 0 or 1 modulo 5. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 1
- **Decomposition sketch:** Nat.pow_mod, case-split on n % 5, decide each of the 5 residue branches (Fermat exponent 4). Verified to build (lake env lean).
