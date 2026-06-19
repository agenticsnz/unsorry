# constrained-prod-le-sum-cubes-third

Among nonnegative reals summing to 1 the product abc is at most 1/27.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog.
- **Reference:** Among nonnegative reals summing to 1 the product abc is at most 1/27. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** reduce to 27abc ≤ (a+b+c)^3 = 1; nlinarith with mul_nonneg of each variable times square of difference of the others. Verified to build (lake env lean) at sourcing.
