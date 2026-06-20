# pell-d3-rational-bound-above

Any positive-index solution of x^2-3y^2=1 satisfies the strict bound 3y^2 < x^2.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Any positive-index solution of x^2-3y^2=1 satisfies the strict bound 3y^2 < x^2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [h, sq_nonneg y, hy]; x^2 = 3y^2+1. Verified to build (lake env lean).
