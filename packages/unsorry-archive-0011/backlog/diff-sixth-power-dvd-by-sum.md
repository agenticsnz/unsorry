# diff-sixth-power-dvd-by-sum

The sum of two integers divides the difference of their sixth powers.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The sum of two integers divides the difference of their sixth powers. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** a^6 - b^6 = (a+b)*(a^5 - a^4*b + a^3*b^2 - a^2*b^3 + a*b^4 - b^5); Dvd.intro + ring. Verified to build (lake env lean).
