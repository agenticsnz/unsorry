# quartic-n4-plus-four-dvd-by-shift-quadratic

The quadratic n^2-2n+2 divides n^4+4, the Sophie Germain factorisation at b equal to one.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The quadratic n^2-2n+2 divides n^4+4, the Sophie Germain factorisation at b equal to one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Provide the conjugate factor n^2+2*n+2 as the Dvd witness and verify with ring. Verified to build (lake env lean).
