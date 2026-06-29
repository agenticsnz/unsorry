# prod-icc-one-add-recip-k-sq-add-two-k-telescope

For n at least 1, the product of (1 + 1/(k^2+2k)) for k from 1 to n equals 2(n+1)/(n+2).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** For n at least 1, the product of (1 + 1/(k^2+2k)) for k from 1 to n equals 2(n+1)/(n+2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 1+1/(k(k+2)) = (k+1)^2/(k(k+2)); the squares telescope as a ratio. Induction from base 1 with Finset.prod_Icc_succ_top, field_simp with k>0, ring. Verified to build (lake env lean).
