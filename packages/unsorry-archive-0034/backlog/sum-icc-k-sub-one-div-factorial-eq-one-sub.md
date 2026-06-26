# sum-icc-k-sub-one-div-factorial-eq-one-sub

For n at least 1, the sum of (k-1)/k! for k from 1 to n equals 1 minus 1/n!.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** For n at least 1, the sum of (k-1)/k! for k from 1 to n equals 1 minus 1/n!. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n from base 1 using Finset.sum_Icc_succ_top; summand (k-1)/k! = 1/(k-1)! - 1/k!, telescopes; field_simp with factorial positivity then ring. Verified to build (lake env lean).
