# gcd-n2-2n5-eq-one

The gcd of n+2 and 2n+5 is always one.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of n+2 and 2n+5 is always one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 2n+5 = 2*(n+2) + 1, so gcd reduces to gcd (n+2) 1 = 1 via gcd_add_mul / Nat.gcd_rec. Verified to build (lake env lean).
