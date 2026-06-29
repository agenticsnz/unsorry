# pell-d2-stormer-seven-ladder-preserves

The √2 fundamental ladder map (x,y) ↦ (3x+4y, 2x+3y) sends a solution of the Pell-like equation x²−2y²=7 to another solution with the same value 7.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** The √2 fundamental ladder map (x,y) ↦ (3x+4y, 2x+3y) sends a solution of the Pell-like equation x²−2y²=7 to another solution with the same value 7. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** linear_combination 7•? — really linear_combination h then ring, since LHS−7 = (form value−7) scaled by the unit. Verified to build (lake env lean).
