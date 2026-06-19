# sum-range-two-k-sub-one-mul-three-pow-closed

The sum of (2k-1) times three-to-the-k over k below n has the clean closed form (n-2)3^n+2.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of (2k-1) times three-to-the-k over k below n has the clean closed form (n-2)3^n+2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; ring closes the linear step. Verified to build (lake env lean).
