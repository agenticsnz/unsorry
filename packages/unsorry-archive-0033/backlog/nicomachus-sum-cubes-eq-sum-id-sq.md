# nicomachus-sum-cubes-eq-sum-id-sq

The sum of the first n cubes equals the square of the sum of the first n naturals (Nicomachus's theorem).

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The sum of the first n cubes equals the square of the sum of the first n naturals (Nicomachus's theorem). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ; rewrite the inner triangular sum via Gauss and close with ring. Verified to build (lake env lean).
