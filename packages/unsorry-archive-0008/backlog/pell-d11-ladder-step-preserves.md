# pell-d11-ladder-step-preserves

Applying the fundamental solution (10,3) of x^2-11y^2=1 to any solution yields another solution.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Applying the fundamental solution (10,3) of x^2-11y^2=1 to any solution yields another solution. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** linear_combination on h after expanding, or nlinarith [h]. Verified to build (lake env lean).
