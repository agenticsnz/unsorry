# pell-d5-ladder-step-preserves

The d=5 fundamental ladder map (x,y) ↦ (9x+20y, 4x+9y) preserves the Pell relation x²−5y²=1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** The d=5 fundamental ladder map (x,y) ↦ (9x+20y, 4x+9y) preserves the Pell relation x²−5y²=1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** linear_combination h after expanding the two squares. Verified to build (lake env lean).
