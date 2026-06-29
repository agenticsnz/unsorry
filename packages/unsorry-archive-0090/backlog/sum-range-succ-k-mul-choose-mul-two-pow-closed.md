# sum-range-succ-k-mul-choose-mul-two-pow-closed

Three times the sum of (k+1) times n-choose-k times two-to-the-k equals (2n+3) times three-to-the-n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Three times the sum of (k+1) times n-choose-k times two-to-the-k equals (2n+3) times three-to-the-n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Split (k+1)=k+1 into the k-weighted moment plus the plain binomial sum 3^n, combine closed forms. Verified to build (lake env lean).
