# pell-d2-x-odd

In every integer solution of x²−2y²=1 the x-coordinate is odd.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** In every integer solution of x²−2y²=1 the x-coordinate is odd. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** x² = 1 + 2y² is odd, so x is odd; via Int.odd_iff and parity of squares (omega after Int.emod reasoning). Verified to build (lake env lean).
