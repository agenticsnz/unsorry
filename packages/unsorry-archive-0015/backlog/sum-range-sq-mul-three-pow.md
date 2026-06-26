# sum-range-sq-mul-three-pow

Twice the sum of k^2·3^k over k below n, plus 3, equals 3^n·(n^2 − 3n + 3).

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog.
- **Reference:** Twice the sum of k^2·3^k over k below n, plus 3, equals 3^n·(n^2 − 3n + 3). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction via Finset.sum_range_succ; factor 3^(n+1) and finish with ring. Verified to build (lake env lean) at sourcing.
