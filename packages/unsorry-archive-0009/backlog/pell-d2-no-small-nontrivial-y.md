# pell-d2-no-small-nontrivial-y

There is no solution of x²−2y²=1 with y=1; the smallest positive y is 2 (the fundamental solution).

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog (#610).
- **Reference:** There is no solution of x²−2y²=1 with y=1; the smallest positive y is 2 (the fundamental solution). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** rule out y=1 (would force x²=3, impossible) via interval_cases/nlinarith, otherwise y≥2. Verified to build (lake env lean).
