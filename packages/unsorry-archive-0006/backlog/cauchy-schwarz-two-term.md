# cauchy-schwarz-two-term

For reals, the square of a dot product of two 2-vectors is at most the product of their squared norms (the two-term Cauchy-Schwarz inequality).

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** For reals, the square of a dot product of two 2-vectors is at most the product of their squared norms (the two-term Cauchy-Schwarz inequality). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [sq_nonneg (a*d - b*c)] (Lagrange identity gives the SOS gap). Verified to build (lake env lean).
