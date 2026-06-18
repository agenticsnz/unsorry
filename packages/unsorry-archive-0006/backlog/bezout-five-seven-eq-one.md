# bezout-five-seven-eq-one

There exist integers x, y with 5x + 7y = 1.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** There exist integers x, y with 5x + 7y = 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Witness x = 3, y = -2 (5*3 + 7*(-2) = 1); supply via refine ⟨3, -2, ?_⟩ then ring/decide. Verified to build (lake env lean).
