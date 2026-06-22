# quad-form-ge-three-quarter-sq

The quadratic form a^2+ab+b^2 is at least three quarters of (a+b)^2.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** The quadratic form a^2+ab+b^2 is at least three quarters of (a+b)^2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with sq_nonneg (a-b); equivalent to (a-b)^2/4 >= 0. Verified to build (lake env lean).
