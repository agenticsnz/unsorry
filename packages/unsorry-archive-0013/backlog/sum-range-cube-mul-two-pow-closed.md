# sum-range-cube-mul-two-pow-closed

The sum of k-cubed times two-to-the-k over k below n has the closed form (n^3-6n^2+18n-26)2^n+26.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of k-cubed times two-to-the-k over k below n has the closed form (n^3-6n^2+18n-26)2^n+26. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ, then ring on the cubic-polynomial coefficient identity. Verified to build (lake env lean).
