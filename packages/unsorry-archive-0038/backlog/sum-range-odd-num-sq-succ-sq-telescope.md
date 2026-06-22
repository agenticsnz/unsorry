# sum-range-odd-num-sq-succ-sq-telescope

The sum of (2k+3)/((k+1)²(k+2)²) for k from 0 to n-1 equals 1 − 1/(n+1)².

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of (2k+3)/((k+1)²(k+2)²) for k from 0 to n-1 equals 1 − 1/(n+1)². Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; per-term identity (2k+3)/((k+1)²(k+2)²) = 1/(k+1)² − 1/(k+2)², field_simp then ring. Verified to build (lake env lean).
