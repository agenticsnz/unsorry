# sum-range-four-consecutive-product

Five times the sum of i(i+1)(i+2)(i+3) over i below n equals (n−1)n(n+1)(n+2)(n+3).

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog (#610).
- **Reference:** Five times the sum of i(i+1)(i+2)(i+3) over i below n equals (n−1)n(n+1)(n+2)(n+3). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Telescoping/induction with Finset.sum_range_succ; ring after handling the n-1 factor. Verified to build (lake env lean).
