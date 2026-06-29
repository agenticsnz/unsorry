# sum-range-even-cols-eq-two-pow

The sum of the even-indexed entries of row 2n of Pascal's triangle equals 2^(2n-1).

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** The sum of the even-indexed entries of row 2n of Pascal's triangle equals 2^(2n-1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Average the full row sum 2^(2n) with the alternating row sum 0 (parity split), via Int.alternating_sum_range_choose. Verified to build (lake env lean).
