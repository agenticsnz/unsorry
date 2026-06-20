# sum-range-choose-mul-succ-choose-succ-eq-central-shift

The sum of n-choose-k times (n+1)-choose-(k+1) equals C(2n+1, n+1).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of n-choose-k times (n+1)-choose-(k+1) equals C(2n+1, n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Reflect the (n+1) factor via symmetry and apply Vandermonde's convolution to land on C(2n+1,n+1). Verified to build (lake env lean).
