# pell-d3-no-negative-solution-zmod3

The negative Pell equation x²−3y²=−1 has no integer solution, because x²≡2 (mod 3) is impossible.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** The negative Pell equation x²−3y²=−1 has no integer solution, because x²≡2 (mod 3) is impossible. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** intro contradiction, reduce mod 3 by mapping through (ZMod 3); decide closes the finite case since 2 is a non-residue. Verified to build (lake env lean).
