# sixth-power-mod-thirtyone-mem

Every sixth power modulo the prime 31 lies in the order-5 subgroup {1,2,4,8,16} together with 0.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every sixth power modulo the prime 31 lies in the order-5 subgroup {1,2,4,8,16} together with 0. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 6 | 30, so nonzero sixth powers form the 5-element subgroup of powers of 2; Nat.pow_mod then decide over n % 31. Verified to build (lake env lean).
