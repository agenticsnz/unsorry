# sum-range-succ-div-factorial-add-two-telescope

The sum of (k+1)/(k+2)! over the first n terms equals 1 minus 1/(n+1)!.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of (k+1)/(k+2)! over the first n terms equals 1 minus 1/(n+1)!. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Summand (k+1)/(k+2)! = 1/(k+1)! - 1/(k+2)!; induction with Finset.sum_range_succ, Nat.factorial_succ rewrites, field_simp on positive factorials, ring. Verified to build (lake env lean).
