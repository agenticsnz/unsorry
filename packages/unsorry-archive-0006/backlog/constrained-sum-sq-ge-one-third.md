# constrained-sum-sq-ge-one-third

If three reals sum to 1 then their sum of squares is at least 1/3.

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** If three reals sum to 1 then their sum of squares is at least 1/3. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith [sq_nonneg (a-b), sq_nonneg (b-c), sq_nonneg (c-a)] using QM-AM with the constraint substituted. Verified to build (lake env lean).
