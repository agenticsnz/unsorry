# constrained-sum-le-sumsq-prod-one

If three positive reals have product 1 then their sum of squares is at least their sum.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog.
- **Reference:** If three positive reals have product 1 then their sum of squares is at least their sum. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [sq_nonneg (a-b), sq_nonneg (b-c), sq_nonneg (c-a), sq_nonneg (a+b+c-3), mul_pos hb hc, ...] using a+b+c ≥ 3 from AM-GM. Verified to build (lake env lean) at sourcing.
