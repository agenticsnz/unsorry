# sum-range-id-mul-choose-eq-half

Twice the sum over k of k times n-choose-k equals n times two-to-the-n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Twice the sum over k of k times n-choose-k equals n times two-to-the-n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Use the absorption identity k*C(n,k)=n*C(n-1,k-1) (Nat.succ_mul_choose_eq) and Nat.sum_range_choose. Verified to build (lake env lean).
