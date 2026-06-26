# sum-range-lower-triangle-choose-eq-two-pow

The double sum of C(j,k) over the lower-triangular index region with j up to n equals 2 to the (n+1) minus 1.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The double sum of C(j,k) over the lower-triangular index region with j up to n equals 2 to the (n+1) minus 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Inner sum collapses to 2^j via Nat.sum_range_choose, then a geometric telescoping induction with Finset.sum_range_succ. Verified to build (lake env lean).
