# pell-d2-convergent-cross-difference

Consecutive √2-convergents produced by the ladder satisfy the determinant relation p_{n+1}q_n − p_n q_{n+1} = −1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** Consecutive √2-convergents produced by the ladder satisfy the determinant relation p_{n+1}q_n − p_n q_{n+1} = −1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** expand and reduce the cross product to −(p²−2q²) then apply h. Verified to build (lake env lean) at sourcing.
