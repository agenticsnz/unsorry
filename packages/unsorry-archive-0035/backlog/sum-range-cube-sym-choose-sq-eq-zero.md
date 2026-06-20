# sum-range-cube-sym-choose-sq-eq-zero

The sum of (n-2k)^3·C(n,k)^2 over k vanishes by the antisymmetry k to n-k.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of (n-2k)^3·C(n,k)^2 over k vanishes by the antisymmetry k to n-k. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Reflection involution k to n-k sends the summand to its negation (odd power times symmetric square); use Finset.sum_involution / sum_range_reflect. Verified to build (lake env lean).
