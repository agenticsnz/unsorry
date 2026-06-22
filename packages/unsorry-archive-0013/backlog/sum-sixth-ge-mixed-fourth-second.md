# sum-sixth-ge-mixed-fourth-second

The sum of sixth powers dominates the mixed terms a⁴b²+a²b⁴.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The sum of sixth powers dominates the mixed terms a⁴b²+a²b⁴. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [sq_nonneg (a-b), sq_nonneg (a+b), sq_nonneg a, sq_nonneg b, mul_nonneg (sq_nonneg a) (sq_nonneg b)]. Verified to build (lake env lean).
