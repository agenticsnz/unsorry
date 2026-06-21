# coprime-2n1-2n3

Two consecutive odd numbers 2n+1 and 2n+3 are coprime.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** Two consecutive odd numbers 2n+1 and 2n+3 are coprime. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Common divisor divides their difference 2 and an odd number, so divides gcd(2,odd)=1; gcd_rec reduction. Verified to build (lake env lean).
