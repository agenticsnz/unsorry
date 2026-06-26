# sum-range-comp-mul-choose-sq-eq

Over the integers the sum of (m-k) times C(m,k) squared, with m = n+1, equals m times C(2m,m) minus m times C(2m-1,m-1).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Over the integers the sum of (m-k) times C(m,k) squared, with m = n+1, equals m times C(2m,m) minus m times C(2m-1,m-1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Write (m-k)=m - k, split into m*sum(C^2)=m*C(2m,m) and sum(k*C^2)=m*C(2m-1,m-1) via sum_range_choose_sq and the k-weighted convolution. Verified to build (lake env lean).
