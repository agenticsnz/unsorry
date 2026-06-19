# pell-d2-positive-multiple-of-form

Any √2-Pell solution satisfies (x−y)(x+y)=y²+1, a factored form of x²−2y²=1 rearranged.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** Any √2-Pell solution satisfies (x−y)(x+y)=y²+1, a factored form of x²−2y²=1 rearranged. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** expand the product to x²−y²; substitute x²=2y²+1 from h, leaving y²+1; linear_combination h. Verified to build (lake env lean).
