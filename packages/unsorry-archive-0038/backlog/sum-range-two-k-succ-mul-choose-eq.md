# sum-range-two-k-succ-mul-choose-eq

The sum of (2k+1) times C(n,k) over k equals (n+1) times 2 to the n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of (2k+1) times C(n,k) over k equals (n+1) times 2 to the n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Split into 2*sum(k*C)=2*n*2^(n-1) and sum(C)=2^n via sum_range_mul_choose and sum_range_choose; combine. Verified to build (lake env lean).
