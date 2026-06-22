# sum-range-recip-five-step-product

The sum of 1/((5k+2)(5k+7)) for k from 0 to n-1 equals n/(2(5n+2)).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of 1/((5k+2)(5k+7)) for k from 0 to n-1 equals n/(2(5n+2)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; per-term ⅕[1/(5k+2) − 1/(5k+7)], field_simp then ring. Verified to build (lake env lean).
