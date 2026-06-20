# cauchy-schwarz-three-var-product

The three-variable Cauchy-Schwarz inequality in product form.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog.
- **Reference:** The three-variable Cauchy-Schwarz inequality in product form. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [sq_nonneg (a*y-b*x), sq_nonneg (b*z-c*y), sq_nonneg (a*z-c*x)] (Lagrange identity SOS). Verified to build (lake env lean) at sourcing.
