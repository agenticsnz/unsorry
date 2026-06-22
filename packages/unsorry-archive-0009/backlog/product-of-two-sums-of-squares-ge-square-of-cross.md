# product-of-two-sums-of-squares-ge-square-of-cross

A product of two sums of squares is at least the square of the antisymmetric cross term (Lagrange consequence).

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** A product of two sums of squares is at least the square of the antisymmetric cross term (Lagrange consequence). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [sq_nonneg (x*z + y*w)] using the Lagrange identity decomposition. Verified to build (lake env lean).
