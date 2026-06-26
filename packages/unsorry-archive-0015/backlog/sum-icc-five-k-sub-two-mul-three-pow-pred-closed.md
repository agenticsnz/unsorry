# sum-icc-five-k-sub-two-mul-three-pow-pred-closed

Four times the sum of (5k-2)*3^(k-1) for k from 1 to n equals (10n-9)*3^n + 9.

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog.
- **Reference:** Four times the sum of (5k-2)*3^(k-1) for k from 1 to n equals (10n-9)*3^n + 9. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_Icc_succ_top; pow_succ on 3^(n+1), lift to ℤ to handle 5k-2 and 10n-9 subtractions, close with ring. Verified to build (lake env lean) at sourcing.
