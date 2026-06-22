# pell-d2-form-product-telescope-step

The √2 norm form is multiplicative along the ladder: multiplying the form value by the fundamental-unit norm equals the form value of the ladder image.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** The √2 norm form is multiplicative along the ladder: multiplying the form value by the fundamental-unit norm equals the form value of the ladder image. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** pure ring identity once 3²−2·2²=1 is folded in; ring closes it without any hypothesis. Verified to build (lake env lean) at sourcing.
