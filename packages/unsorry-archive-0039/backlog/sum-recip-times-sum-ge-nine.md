# sum-recip-times-sum-ge-nine

For positive reals, (a+b+c)(1/a+1/b+1/c) is at least 9 (Cauchy-Schwarz / AM-HM corollary).

- **Source:** #400 Identity Engine (ADR-043) — inequality (SOS) family; promoted from candidate backlog (#610).
- **Reference:** For positive reals, (a+b+c)(1/a+1/b+1/c) is at least 9 (Cauchy-Schwarz / AM-HM corollary). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** clear denominators via field_simp, then nlinarith with sq_nonneg of pairwise differences. Verified to build (lake env lean).
