# shifted-sophie-germain-x4-plus-4-dvd-by-x2-plus-2x-plus-2

The quadratic x^2+2x+2 divides x^4+4 (one Sophie-Germain factor at b=1).

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The quadratic x^2+2x+2 divides x^4+4 (one Sophie-Germain factor at b=1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** x^4 + 4 = (x^2 + 2x + 2)*(x^2 - 2x + 2); supply cofactor then ring. Verified to build (lake env lean).
