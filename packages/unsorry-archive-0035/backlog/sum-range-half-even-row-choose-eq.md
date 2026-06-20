# sum-range-half-even-row-choose-eq

Twice the sum of the first n+1 entries of the even row 2n of Pascal's triangle equals 4 to the n plus the central coefficient C(2n,n).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Twice the sum of the first n+1 entries of the even row 2n of Pascal's triangle equals 4 to the n plus the central coefficient C(2n,n). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Symmetry choose_symm folds the upper half onto the lower half; the full even row sums to 2^(2n)=4^n and the central term is counted once, so doubling the half adds C(2n,n). Verified to build (lake env lean).
