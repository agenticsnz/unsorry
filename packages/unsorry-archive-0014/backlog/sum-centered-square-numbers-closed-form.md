# sum-centered-square-numbers-closed-form

Three times the running sum of centered square numbers 2k(k+1)+1 equals n(2n^2+1).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Three times the running sum of centered square numbers 2k(k+1)+1 equals n(2n^2+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction over Finset.range n with sum_range_succ; ring closes after the factor-3 clears denominators. Verified to build (lake env lean).
