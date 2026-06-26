# sum-five-consecutive-product-closed-form

Six times the sum of five consecutive integer products equals the six-term product n through n+5, the 5-simplex closed form.

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Six times the sum of five consecutive integer products equals the six-term product n through n+5, the 5-simplex closed form. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Telescoping induction via Finset.sum_range_succ; ring. Verified to build (lake env lean).
