# sum-range-cube-mul-three-pow-closed

Eight times the sum of k-cubed times three-to-the-k over k below n equals (4n^3-18n^2+36n-33)3^n+33.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Eight times the sum of k-cubed times three-to-the-k over k below n equals (4n^3-18n^2+36n-33)3^n+33. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction with Finset.sum_range_succ; ring discharges the cubic step after clearing the 8. Verified to build (lake env lean).
