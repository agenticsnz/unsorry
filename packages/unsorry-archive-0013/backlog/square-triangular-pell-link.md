# square-triangular-pell-link

A square triangular number m²=T_k is equivalent to the Pell solution (2k+1)²−8m²=1, linking T_k to x²−8y²=1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** A square triangular number m²=T_k is equivalent to the Pell solution (2k+1)²−8m²=1, linking T_k to x²−8y²=1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** linear_combination h; pure rearrangement of the hypothesis. Verified to build (lake env lean).
