# sum-range-stirling-first-row-eq-factorial

The sum of the unsigned Stirling numbers of the first kind across a full row equals n factorial, since every permutation of an n-set decomposes into some number of cycles.

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog.
- **Reference:** The sum of the unsigned Stirling numbers of the first kind across a full row equals n factorial, since every permutation of an n-set decomposes into some number of cycles. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n with stirlingFirst_succ_succ; the step Finset.sum splits via the recurrence stirlingFirst (n+1) k = n·stirlingFirst n k + stirlingFirst n (k-1) and collapses to n·n! + n! = (n+1)!. Verified to build (lake env lean) at sourcing.
