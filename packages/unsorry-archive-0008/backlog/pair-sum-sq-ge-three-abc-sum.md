# pair-sum-sq-ge-three-abc-sum

The square of the elementary symmetric sum ab+bc+ca is at least 3abc(a+b+c) for all reals (Newton/Maclaurin).

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog.
- **Reference:** The square of the elementary symmetric sum ab+bc+ca is at least 3abc(a+b+c) for all reals (Newton/Maclaurin). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** nlinarith with sq_nonneg (a*b-b*c), sq_nonneg (b*c-c*a), sq_nonneg (c*a-a*b). Verified to build (lake env lean) at sourcing.
