# sum-range-recip-five-step-residue-one

The sum of 5/((5k+1)(5k+6)) for k from 0 to n-1 telescopes to 1 minus 1/(5n+1).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of 5/((5k+1)(5k+6)) for k from 0 to n-1 telescopes to 1 minus 1/(5n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n; term equals 1/(5k+1) - 1/(5k+6); finish with field_simp and ring. Verified to build (lake env lean).
