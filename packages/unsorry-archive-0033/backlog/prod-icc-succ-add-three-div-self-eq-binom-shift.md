# prod-icc-succ-add-three-div-self-eq-binom-shift

The product of (k+3)/k for k from 1 to n telescopes to (n+1)(n+2)(n+3)/6.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog.
- **Reference:** The product of (k+3)/k for k from 1 to n telescopes to (n+1)(n+2)(n+3)/6. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Step-3 telescoping product; induct via prod_Icc_succ_top with 1 ≤ n, field_simp, ring. Verified to build (lake env lean) at sourcing.
