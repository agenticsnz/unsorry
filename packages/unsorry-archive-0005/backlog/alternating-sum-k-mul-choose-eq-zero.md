# alternating-sum-k-mul-choose-eq-zero

For n at least 2 the alternating sum of k·C(n,k) over k is zero.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** For n at least 2 the alternating sum of k·C(n,k) over k is zero. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Rewrite k·C(n,k)=n·C(n-1,k-1), factor out n, reindex, then apply Int.alternating_sum_range_choose. Verified to build (lake env lean).
