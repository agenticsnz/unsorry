# quartic-sum-ge-abc-times-sum

The sum of fourth powers of three reals dominates abc times their sum a+b+c.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog.
- **Reference:** The sum of fourth powers of three reals dominates abc times their sum a+b+c. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** chain a^4+b^4+c^4 ≥ a^2b^2+b^2c^2+c^2a^2 ≥ abc(a+b+c); nlinarith with sq_nonneg of squared differences and product differences. Verified to build (lake env lean) at sourcing.
