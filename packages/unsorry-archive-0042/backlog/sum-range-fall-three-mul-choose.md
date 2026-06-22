# sum-range-fall-three-mul-choose

The sum over k of the third falling factorial of k times C(n,k), scaled by 8, equals n(n-1)(n-2) times 2^n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum over k of the third falling factorial of k times C(n,k), scaled by 8, equals n(n-1)(n-2) times 2^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Induction with Finset.sum_range_succ plus Nat.succ_mul_choose_eq absorption; companion to the existing degree-2 falling goal. Verified to build (lake env lean).
