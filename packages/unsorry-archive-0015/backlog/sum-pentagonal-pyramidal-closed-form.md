# sum-pentagonal-pyramidal-closed-form

Twelve times the sum of k^2(k+1) (twice the pentagonal-pyramidal terms) equals n(n+1)(3n+1)(n+2).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Twelve times the sum of k^2(k+1) (twice the pentagonal-pyramidal terms) equals n(n+1)(3n+1)(n+2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; expand k^2(k+1)=k^3+k^2 and combine Faulhaber pieces, ring on the step. Verified to build (lake env lean).
