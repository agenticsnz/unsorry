# sum-range-k-mul-factorial-succ

One plus the sum of k times k-factorial over k below n equals n-factorial.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** One plus the sum of k times k-factorial over k below n equals n-factorial. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n using Finset.sum_range_succ and Nat.factorial_succ; finish with ring/omega on the factorial step. Verified to build (lake env lean).
