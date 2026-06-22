# sum-range-recip-three-consecutive

The telescoping sum of 1/((k+1)(k+2)(k+3)) over k below n equals 1/4 − 1/(2(n+1)(n+2)).

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog (#610).
- **Reference:** The telescoping sum of 1/((k+1)(k+2)(k+3)) over k below n equals 1/4 − 1/(2(n+1)(n+2)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction with Finset.sum_range_succ; field_simp then ring on the telescoped tail. Verified to build (lake env lean).
