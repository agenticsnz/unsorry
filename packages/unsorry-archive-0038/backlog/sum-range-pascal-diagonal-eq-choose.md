# sum-range-pascal-diagonal-eq-choose

The hockey-stick along a Pascal diagonal: the sum of C(m+k,k) for k from 0 to n equals C(m+n+1,n).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The hockey-stick along a Pascal diagonal: the sum of C(m+k,k) for k from 0 to n equals C(m+n+1,n). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ and Nat.succ_sub_one / choose_succ_succ Pascal step; a parallel-diagonal hockey-stick distinct from the Icc form. Verified to build (lake env lean).
