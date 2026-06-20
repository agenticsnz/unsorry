# sum-centered-triangular-closed-form

The sum of the first n centered triangular numbers equals n times (n^2+1).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog.
- **Reference:** The sum of the first n centered triangular numbers equals n times (n^2+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n; Finset.sum_range_succ then nlinarith handling 3k^2-3k Nat subtraction. Verified to build (lake env lean) at sourcing.
