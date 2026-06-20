# pell-brahmagupta-composition-d2

Brahmagupta composition: multiplying two solutions of x²−2y²=1 via (ac+2be, ae+bc) gives another solution.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Brahmagupta composition: multiplying two solutions of x²−2y²=1 via (ac+2be, ae+bc) gives another solution. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** nlinarith [h1, h2] or linear_combination c^2*h1 + ... ; the product of the two relations equals the goal LHS. Verified to build (lake env lean).
