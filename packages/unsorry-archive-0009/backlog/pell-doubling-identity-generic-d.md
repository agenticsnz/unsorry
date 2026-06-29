# pell-doubling-identity-generic-d

Squaring a fundamental-type solution via (a²+db², 2ab) again solves x²−dy²=1, for any d.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Squaring a fundamental-type solution via (a²+db², 2ab) again solves x²−dy²=1, for any d. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** LHS = (a²−d·b²)² as a ring identity; substitute h so it becomes 1² = 1 via linear_combination. Verified to build (lake env lean).
