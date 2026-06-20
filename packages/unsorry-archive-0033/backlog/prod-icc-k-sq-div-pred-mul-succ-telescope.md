# prod-icc-k-sq-div-pred-mul-succ-telescope

The product of k^2/((k-1)(k+1)) for k from 2 to n telescopes to 2n/(n+1).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog.
- **Reference:** The product of k^2/((k-1)(k+1)) for k from 2 to n telescopes to 2n/(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Factor as (k/(k-1))(k/(k+1)); each factor telescopes; induct via prod_Icc_succ_top with 2 ≤ n, field_simp, ring. Verified to build (lake env lean) at sourcing.
