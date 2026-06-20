# pell-d3-fundamental-square-doubling

Squaring a solution of x²−3y²=1 via (x²+3y², 2xy) again solves x²−3y²=1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Squaring a solution of x²−3y²=1 via (x²+3y², 2xy) again solves x²−3y²=1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** LHS = (x²−3y²)² by ring; substitute h via linear_combination to reach 1. Verified to build (lake env lean).
