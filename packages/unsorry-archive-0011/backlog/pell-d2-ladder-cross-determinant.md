# pell-d2-ladder-cross-determinant

For a √2-Pell solution, the cross-determinant of (x,y) with its ladder image (3x+4y, 2x+3y) equals −2.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** For a √2-Pell solution, the cross-determinant of (x,y) with its ladder image (3x+4y, 2x+3y) equals −2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** the expression simplifies to −2(x²−2y²) by ring; rewrite with h to get −2. Verified to build (lake env lean).
