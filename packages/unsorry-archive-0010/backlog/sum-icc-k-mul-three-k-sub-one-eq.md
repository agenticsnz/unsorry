# sum-icc-k-mul-three-k-sub-one-eq

The sum of k(3k-1) for k from 1 to n, twice the generalized pentagonal numbers, equals n²(n+1).

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog (#610).
- **Reference:** The sum of k(3k-1) for k from 1 to n, twice the generalized pentagonal numbers, equals n²(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n with Finset.sum_Icc_succ_top, then ring/omega on the step. Verified to build (lake env lean).
