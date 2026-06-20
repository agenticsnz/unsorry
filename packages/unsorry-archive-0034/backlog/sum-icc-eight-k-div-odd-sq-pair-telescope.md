# sum-icc-eight-k-div-odd-sq-pair-telescope

The sum of 8k/((2k-1)^2(2k+1)^2) for k from 1 to n telescopes to 1 minus 1/(2n+1)^2.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog.
- **Reference:** The sum of 8k/((2k-1)^2(2k+1)^2) for k from 1 to n telescopes to 1 minus 1/(2n+1)^2. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Term equals 1/(2k-1)^2 - 1/(2k+1)^2; induct via sum_Icc_succ_top, then field_simp and ring. Verified to build (lake env lean) at sourcing.
