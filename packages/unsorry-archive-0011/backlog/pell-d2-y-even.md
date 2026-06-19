# pell-d2-y-even

The product xy of any integer solution of x²−2y²=1 is even.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** The product xy of any integer solution of x²−2y²=1 is even. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** x is odd; if y odd then x²−2y² ≡ 1−2 ≡ 3 (mod 4) contradicting =1, so y even, hence xy even — ZMod 4 / decide bridge. Verified to build (lake env lean).
