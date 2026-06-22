# pell-d7-ladder-step-preserves

The d=7 fundamental ladder map (x,y) ↦ (8x+21y, 3x+8y), from the solution (8,3), preserves x²−7y²=1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** The d=7 fundamental ladder map (x,y) ↦ (8x+21y, 3x+8y), from the solution (8,3), preserves x²−7y²=1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** linear_combination h after expanding both squares. Verified to build (lake env lean).
