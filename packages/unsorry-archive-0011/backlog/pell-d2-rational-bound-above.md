# pell-d2-rational-bound-above

Every positive Pell solution of x²−2y²=1 makes x/y exceed √2, i.e. 2y² < x².

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Every positive Pell solution of x²−2y²=1 makes x/y exceed √2, i.e. 2y² < x². Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** x² = 2y² + 1 > 2y²; linarith after rewriting h, but with the strict gap it needs nlinarith on positivity. Verified to build (lake env lean).
