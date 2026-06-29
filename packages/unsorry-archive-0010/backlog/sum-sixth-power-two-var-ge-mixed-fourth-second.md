# sum-sixth-power-two-var-ge-mixed-fourth-second

The sum of sixth powers of two reals dominates the mixed fourth-second power terms.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The sum of sixth powers of two reals dominates the mixed fourth-second power terms. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** factor a^6+b^6 - a^4 b^2 - a^2 b^4 = (a^2-b^2)^2 (a^2+b^2); nlinarith [sq_nonneg (a^2-b^2), sq_nonneg a, sq_nonneg b, mul_nonneg ...]. Verified to build (lake env lean).
