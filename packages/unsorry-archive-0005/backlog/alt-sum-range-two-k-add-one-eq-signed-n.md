# alt-sum-range-two-k-add-one-eq-signed-n

The alternating sum of the odd numbers (2k+1) over k below n equals (-1)^(n+1) times n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The alternating sum of the odd numbers (2k+1) over k below n equals (-1)^(n+1) times n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; case on parity via pow_succ and close with ring. Verified to build (lake env lean).
