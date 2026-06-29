# sum-fourth-powers-ge-cube-times-sum

For nonnegative reals, a^3 b + a b^3 is at most a^4 + b^4.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog.
- **Reference:** For nonnegative reals, a^3 b + a b^3 is at most a^4 + b^4. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with sq_nonneg (a-b) and sq_nonneg (a+b) times sq_nonneg (a-b) as SOS hints. Verified to build (lake env lean) at sourcing.
