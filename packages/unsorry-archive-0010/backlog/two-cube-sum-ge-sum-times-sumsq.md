# two-cube-sum-ge-sum-times-sumsq

For nonnegative reals twice the sum of cubes dominates (a+b)(a^2+b^2).

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** For nonnegative reals twice the sum of cubes dominates (a+b)(a^2+b^2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** nlinarith with mul_nonneg (add_nonneg ha hb) (sq_nonneg (a-b)); it is (a+b)(a-b)^2 >= 0. Verified to build (lake env lean).
