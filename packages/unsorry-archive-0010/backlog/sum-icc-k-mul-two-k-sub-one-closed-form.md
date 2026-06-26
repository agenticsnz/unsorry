# sum-icc-k-mul-two-k-sub-one-closed-form

Six times the sum of k(2k-1) for k from 1 to n equals n(n+1)(4n-1).

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog (#610).
- **Reference:** Six times the sum of k(2k-1) for k from 1 to n equals n(n+1)(4n-1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_Icc_succ_top; the step is a cubic identity closed by ring (after clearing the 2k-1 subtraction) or omega. Verified to build (lake env lean).
