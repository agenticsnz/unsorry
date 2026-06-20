# eleventh-power-mod-twentythree-mem

Every eleventh power is congruent to only 0, 1 or 22 modulo the prime 23.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every eleventh power is congruent to only 0, 1 or 22 modulo the prime 23. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 11 | 22 so nonzero eleventh powers are ±1 (the quadratic-residue Euler criterion); Nat.pow_mod then decide over n % 23. Verified to build (lake env lean).
