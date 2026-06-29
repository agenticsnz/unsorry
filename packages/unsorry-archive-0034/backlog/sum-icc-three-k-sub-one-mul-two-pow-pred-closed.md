# sum-icc-three-k-sub-one-mul-two-pow-pred-closed

The sum of (3k-1)*2^(k-1) for k from 1 to n equals (3n-4)*2^n + 4.

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog.
- **Reference:** The sum of (3k-1)*2^(k-1) for k from 1 to n equals (3n-4)*2^n + 4. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_Icc_succ_top; rewrite 2^(k-1) carefully, pow_succ, and close the step in ℤ via ring (lift to avoid ℕ subtraction). Verified to build (lake env lean) at sourcing.
