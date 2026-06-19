# shifted-sum-sq-ge-twice-sum-three-var

Each variable's square plus one dominates twice the variable, summed over three variables.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** Each variable's square plus one dominates twice the variable, summed over three variables. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with sq_nonneg (a-1), sq_nonneg (b-1), sq_nonneg (c-1). Verified to build (lake env lean).
