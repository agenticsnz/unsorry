# diff-twelfth-power-dvd-by-diff-cube

The difference of cubes divides the difference of twelfth powers.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The difference of cubes divides the difference of twelfth powers. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** a^12 - b^12 = (a^3 - b^3)*(a^9 + a^6 b^3 + a^3 b^6 + b^9); Dvd.intro + ring. Verified to build (lake env lean).
