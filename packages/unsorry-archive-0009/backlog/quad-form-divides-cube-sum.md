# quad-form-divides-cube-sum

The quadratic a²-ab+b² divides the sum of cubes a³+b³.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The quadratic a²-ab+b² divides the sum of cubes a³+b³. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 1
- **Decomposition sketch:** exact ⟨a + b, by ring⟩. Verified to build (lake env lean).
