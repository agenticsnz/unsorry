# gcd-n-add-six-dvd-six

The gcd of n and n+6 always divides 6.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The gcd of n and n+6 always divides 6. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** gcd n (n+6) divides the difference (n+6)-n = 6; use gcd_dvd_right minus gcd_dvd_left and Nat.dvd_sub. Verified to build (lake env lean).
