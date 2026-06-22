# prod-icc-one-sub-two-div-pronic

The product of (1 − 2/(k(k+1))) for k from 2 to n equals (n+2)/(3n).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The product of (1 − 2/(k(k+1))) for k from 2 to n equals (n+2)/(3n). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; rewrite 1 − 2/(k(k+1)) = (k−1)(k+2)/(k(k+1)) and telescope both linear chains, field_simp + ring. Verified to build (lake env lean).
