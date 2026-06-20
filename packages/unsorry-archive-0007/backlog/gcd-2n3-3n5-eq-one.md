# gcd-2n3-3n5-eq-one

The linear forms 2n+3 and 3n+5 (determinant 1) are coprime for every n.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog.
- **Reference:** The linear forms 2n+3 and 3n+5 (determinant 1) are coprime for every n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Bezout: 3*(2n+3)-2*(3n+5)=-1; reduce gcd to gcd of a constant 1. Verified to build (lake env lean) at sourcing.
