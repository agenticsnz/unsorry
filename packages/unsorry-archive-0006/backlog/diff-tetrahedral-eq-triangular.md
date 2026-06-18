# diff-tetrahedral-eq-triangular

The difference of two consecutive tetrahedral numbers equals the intervening triangular number.

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** The difference of two consecutive tetrahedral numbers equals the intervening triangular number. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Rewrite each Nat division via divisibility (6 ∣ product, 2 ∣ product), then omega / ring on the integers. Verified to build (lake env lean).
