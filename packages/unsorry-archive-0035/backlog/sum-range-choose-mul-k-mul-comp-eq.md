# sum-range-choose-mul-k-mul-comp-eq

Four times the sum of C(n,k)·k·(n-k) equals n(n-1)·2^n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Four times the sum of C(n,k)·k·(n-k) equals n(n-1)·2^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Absorb both factors via k·C(n,k)=n·C(n-1,k-1) and symmetry, reducing to sum_range_choose; relates to variance of the binomial. Verified to build (lake env lean).
