# two-mul-sum-icc-three-k-sub-two-eq-pentagonal

Twice the sum of (3k-2) for k from 1 to n equals n(3n-1), making the n-th partial sum the pentagonal number P_n.

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog (#610).
- **Reference:** Twice the sum of (3k-2) for k from 1 to n equals n(3n-1), making the n-th partial sum the pentagonal number P_n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_Icc_succ_top, clearing Nat subtraction via the doubled form and omega. Verified to build (lake env lean).
