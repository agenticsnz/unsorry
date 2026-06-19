# gcd-n3-2n7-eq-one

The linear forms n+3 and 2n+7 are coprime for every natural number n.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The linear forms n+3 and 2n+7 are coprime for every natural number n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** g | 2*(n+3)=2n+6 and g | 2n+7; difference is 1, so g | 1. Verified to build (lake env lean).
