# alternating-sum-shifted-choose-eq-one

The alternating sum of the shifted binomial coefficients C(n+1,k+1) equals 1.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The alternating sum of the shifted binomial coefficients C(n+1,k+1) equals 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Reindex into the full alternating row sum for n+1 (which is 0), isolating the missing k=0 term via Int.alternating_sum_range_choose. Verified to build (lake env lean).
