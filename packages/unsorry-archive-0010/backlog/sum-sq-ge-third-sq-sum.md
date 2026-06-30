# sum-sq-ge-third-sq-sum

The mean-square form: one third of the squared sum is at most the sum of squares (QM-AM in fractional form).

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** The mean-square form: one third of the squared sum is at most the sum of squares (QM-AM in fractional form). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with sq_nonneg (a-b), sq_nonneg (b-c), sq_nonneg (c-a). Verified to build (lake env lean).
