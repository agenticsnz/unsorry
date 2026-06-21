# gcd-3n1-9n4-eq-one

The gcd of 3n+1 and 9n+4 is always one.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of 3n+1 and 9n+4 is always one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 9n+4 = 3*(3n+1) + 1, so gcd (3n+1) (9n+4) = gcd (3n+1) 1 = 1. Verified to build (lake env lean).
