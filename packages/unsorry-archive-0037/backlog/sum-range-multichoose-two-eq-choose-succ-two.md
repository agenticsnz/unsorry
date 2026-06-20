# sum-range-multichoose-two-eq-choose-succ-two

Summing the size-j multiset counts from a two-element set over j up to m gives the triangular number C(m+2, 2).

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog (#610).
- **Reference:** Summing the size-j multiset counts from a two-element set over j up to m gives the triangular number C(m+2, 2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Use multichoose_two (= j+1) to turn the sum into ∑ (j+1) = (m+1)(m+2)/2; then identify with choose_two_right and close with omega/ring after Gauss summation. Verified to build (lake env lean).
