# sextic-x6-plus-x3-plus-one-composite-shift

The ninth cyclotomic polynomial n⁶+n³+1 divides n⁹-1.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The ninth cyclotomic polynomial n⁶+n³+1 divides n⁹-1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** exact ⟨n^3 - 1, by ring⟩. Verified to build (lake env lean).
