# sum-range-sq-mul-two-pow

The sum of k^2·2^k over k below n, plus 6, equals 2^n·(n^2 − 4n + 6).

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog.
- **Reference:** The sum of k^2·2^k over k below n, plus 6, equals 2^n·(n^2 − 4n + 6). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; note n^2-4n+6 stays nonneg, ring/nlinarith on step. Verified to build (lake env lean) at sourcing.
