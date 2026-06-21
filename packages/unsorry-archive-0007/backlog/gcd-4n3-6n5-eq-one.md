# gcd-4n3-6n5-eq-one

The gcd of 4n+3 and 6n+5 is always one.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of 4n+3 and 6n+5 is always one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 3*(4n+3) - 2*(6n+5) = -1; a common divisor divides 1, so the gcd is 1 via subtraction steps. Verified to build (lake env lean).
