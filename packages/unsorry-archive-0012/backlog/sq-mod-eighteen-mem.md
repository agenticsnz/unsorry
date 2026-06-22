# sq-mod-eighteen-mem

Every perfect square lies in {0,1,4,7,9,10,13,16} modulo 18.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every perfect square lies in {0,1,4,7,9,10,13,16} modulo 18. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Rewrite n^2 % 18 with Nat.pow_mod and case-split on n % 18 via decide. Verified to build (lake env lean).
