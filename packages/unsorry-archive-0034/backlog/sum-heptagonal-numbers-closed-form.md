# sum-heptagonal-numbers-closed-form

Three times the sum of the first n heptagonal numbers (twice each, as k(5k-3)) equals n(n+1)(5n-2).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Three times the sum of the first n heptagonal numbers (twice each, as k(5k-3)) equals n(n+1)(5n-2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ, then ring (Nat subtraction stays nonnegative for k,n ≥ 1). Verified to build (lake env lean).
