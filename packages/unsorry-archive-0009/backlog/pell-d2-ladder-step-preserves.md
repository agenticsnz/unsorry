# pell-d2-ladder-step-preserves

Applying the fundamental Pell ladder map (x,y) ↦ (3x+4y, 2x+3y) to any solution of x²−2y²=1 yields another solution.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Applying the fundamental Pell ladder map (x,y) ↦ (3x+4y, 2x+3y) to any solution of x²−2y²=1 yields another solution. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** linear_combination using the hypothesis after ring-normalising the expanded square. Verified to build (lake env lean).
