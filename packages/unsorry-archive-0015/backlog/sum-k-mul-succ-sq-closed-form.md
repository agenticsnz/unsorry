# sum-k-mul-succ-sq-closed-form

Twelve times the sum of k(k+1)^2 equals n(n+1)(n+2)(3n+5).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Twelve times the sum of k(k+1)^2 equals n(n+1)(n+2)(3n+5). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ then ring; factor-12 clears the rational closed form. Verified to build (lake env lean).
