# pell-d2-rational-bound-gap

The √2-approximation gap is controlled: for a solution of x²−2y²=1 one has x²−2y² ≤ y²+1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** The √2-approximation gap is controlled: for a solution of x²−2y²=1 one has x²−2y² ≤ y²+1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** rewrite h to get 1 ≤ y²+1; nlinarith [sq_nonneg y]. Verified to build (lake env lean).
