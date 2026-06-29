# sum-icc-recip-km1-k-kp1-telescope

For n at least 2, the sum of 1/((k-1)k(k+1)) for k from 2 to n equals 1/4 minus 1/(2n(n+1)).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** For n at least 2, the sum of 1/((k-1)k(k+1)) for k from 2 to n equals 1/4 minus 1/(2n(n+1)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Summand = 1/2[1/((k-1)k) - 1/(k(k+1))]; induction from base 2 with Finset.sum_Icc_succ_top, field_simp with k≥2, ring. Verified to build (lake env lean).
