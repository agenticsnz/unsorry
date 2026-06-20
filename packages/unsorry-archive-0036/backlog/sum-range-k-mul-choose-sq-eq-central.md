# sum-range-k-mul-choose-sq-eq-central

The sum of k·C(n,k)^2 equals n times the binomial coefficient C(2n-1,n-1).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of k·C(n,k)^2 equals n times the binomial coefficient C(2n-1,n-1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Absorb k via n·C(n-1,k-1)·C(n,k), then a Vandermonde convolution; not a single battery tactic. Verified to build (lake env lean).
