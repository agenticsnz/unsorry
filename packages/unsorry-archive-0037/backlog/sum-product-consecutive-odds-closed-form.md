# sum-product-consecutive-odds-closed-form

Three times the sum of products of consecutive odd numbers (2k-1)(2k+1) equals n(4n^2+6n-1).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Three times the sum of products of consecutive odd numbers (2k-1)(2k+1) equals n(4n^2+6n-1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; the summand is 4k^2-1, ring closes after factor-3. Verified to build (lake env lean).
