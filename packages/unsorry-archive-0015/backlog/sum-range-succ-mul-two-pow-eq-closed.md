# sum-range-succ-mul-two-pow-eq-closed

The derivative-of-geometric-series sum ∑ (k+1)·2^k from k=0 to n has closed form n·2^(n+1)+1.

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog (#610).
- **Reference:** The derivative-of-geometric-series sum ∑ (k+1)·2^k from k=0 to n has closed form n·2^(n+1)+1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ and ring. Verified to build (lake env lean).
