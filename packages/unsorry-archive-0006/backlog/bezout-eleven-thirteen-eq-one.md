# bezout-eleven-thirteen-eq-one

There exist integers x, y with 11x + 13y = 1.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** There exist integers x, y with 11x + 13y = 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Witness x = 6, y = -5 (11*6 + 13*(-5) = 1); refine ⟨6, -5, ?_⟩ then ring. Verified to build (lake env lean).
