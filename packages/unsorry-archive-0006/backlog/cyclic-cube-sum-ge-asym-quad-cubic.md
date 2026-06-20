# cyclic-cube-sum-ge-asym-quad-cubic

For nonnegative reals the sum of cubes dominates the cyclic sum a^2 b + b^2 c + c^2 a.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog.
- **Reference:** For nonnegative reals the sum of cubes dominates the cyclic sum a^2 b + b^2 c + c^2 a. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with mul_nonneg products and sq_nonneg (a-b),(b-c),(c-a) weighted by the variables. Verified to build (lake env lean) at sourcing.
