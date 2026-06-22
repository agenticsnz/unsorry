# pell-d7-no-negative-solution-zmod7

The negative Pell equation x²−7y²=−1 has no integer solution, since 6 is a quadratic non-residue mod 7.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** The negative Pell equation x²−7y²=−1 has no integer solution, since 6 is a quadratic non-residue mod 7. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** assume equality, push to ZMod 7 via a ring hom, then decide on the finite quotient rules out x²=6. Verified to build (lake env lean) at sourcing.
