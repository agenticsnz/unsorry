# sum-range-id-div-two-pow-eq-two-sub

The sum of k over two-to-the-k for k below n equals two minus (2n+2)/2^n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of k over two-to-the-k for k below n equals two minus (2n+2)/2^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction with Finset.sum_range_succ over ℚ; field_simp and ring on the doubling denominator. Verified to build (lake env lean).
