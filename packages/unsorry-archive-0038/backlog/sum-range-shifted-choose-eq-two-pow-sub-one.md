# sum-range-shifted-choose-eq-two-pow-sub-one

The sum of the shifted binomial coefficients C(n+1,k+1) for k from 0 to n equals 2^(n+1) minus 1.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of the shifted binomial coefficients C(n+1,k+1) for k from 0 to n equals 2^(n+1) minus 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Reindex against sum_range_choose for n+1, peeling off the C(n+1,0)=1 term. Verified to build (lake env lean).
