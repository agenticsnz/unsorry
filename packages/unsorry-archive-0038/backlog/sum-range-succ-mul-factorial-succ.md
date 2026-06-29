# sum-range-succ-mul-factorial-succ

The sum of (i+1)·(i+1)! over i below n, plus 1, telescopes to (n+1)!.

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog (#610).
- **Reference:** The sum of (i+1)·(i+1)! over i below n, plus 1, telescopes to (n+1)!. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; use Nat.factorial_succ then ring. Verified to build (lake env lean).
