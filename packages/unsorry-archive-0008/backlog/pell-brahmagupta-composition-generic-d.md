# pell-brahmagupta-composition-generic-d

For every parameter d, the Brahmagupta product (ac+dbe, ae+bc) composes two solutions of x²−dy²=1 into a third.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** For every parameter d, the Brahmagupta product (ac+dbe, ae+bc) composes two solutions of x²−dy²=1 into a third. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** show LHS = (a²−d·b²)(c²−d·e²) by ring, then rewrite both hypotheses via linear_combination. Verified to build (lake env lean).
