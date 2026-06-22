# sum-icc-three-div-three-k-sub-one-three-k-add-two-telescope

The sum of 3/((3k-1)(3k+2)) for k from 1 to n telescopes to 1/2 minus 1/(3n+2).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of 3/((3k-1)(3k+2)) for k from 1 to n telescopes to 1/2 minus 1/(3n+2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n with Finset.sum_Icc_succ_top; term is 1/(3k-1) - 1/(3k+2); field_simp and ring. Verified to build (lake env lean).
