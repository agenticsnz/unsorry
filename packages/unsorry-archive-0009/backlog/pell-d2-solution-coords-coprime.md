# pell-d2-solution-coords-coprime

In any integer solution of x²−2y²=1 the two coordinates are coprime, since any common divisor squared divides 1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** In any integer solution of x²−2y²=1 the two coordinates are coprime, since any common divisor squared divides 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** exhibit the Bézout combination x·x + (-2·y)·y = 1 from h, giving IsCoprime via the definition. Verified to build (lake env lean) at sourcing.
