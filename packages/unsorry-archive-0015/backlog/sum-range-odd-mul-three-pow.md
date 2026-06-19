# sum-range-odd-mul-three-pow

The sum of (2i+1)·3^i over i below n, plus 3^n, equals n·3^n + 1.

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog (#610).
- **Reference:** The sum of (2i+1)·3^i over i below n, plus 3^n, equals n·3^n + 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n via Finset.sum_range_succ; close inductive step with ring. Verified to build (lake env lean).
