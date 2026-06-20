# prod-icc-one-sub-recip-sq-eq-frac

The product of (k²−1)/k² for k from 2 to n equals (n+1)/(2n).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The product of (k²−1)/k² for k from 2 to n equals (n+1)/(2n). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction; factor k²−1 = (k−1)(k+1) and telescope the two linear chains, field_simp + ring. Verified to build (lake env lean).
