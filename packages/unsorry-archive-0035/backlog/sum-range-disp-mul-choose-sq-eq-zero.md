# sum-range-disp-mul-choose-sq-eq-zero

Over the integers the sum of (n-2k) times C(n,k) squared vanishes by the reflection symmetry k to n-k.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Over the integers the sum of (n-2k) times C(n,k) squared vanishes by the reflection symmetry k to n-k. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Reflection involution k↦n-k via Finset.sum_range_reflect negates the linear displacement while fixing the symmetric square C(n,k)^2; antisymmetry forces zero. Verified to build (lake env lean).
