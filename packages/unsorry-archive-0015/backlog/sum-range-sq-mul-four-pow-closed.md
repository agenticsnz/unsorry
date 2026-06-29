# sum-range-sq-mul-four-pow-closed

Twenty-seven times the sum of k-squared times four-to-the-k over k below n equals (9n^2-24n+20)4^n-20.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Twenty-seven times the sum of k-squared times four-to-the-k over k below n equals (9n^2-24n+20)4^n-20. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction with Finset.sum_range_succ; ring on the quadratic step after clearing the 27. Verified to build (lake env lean).
