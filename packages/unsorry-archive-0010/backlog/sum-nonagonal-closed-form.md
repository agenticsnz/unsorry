# sum-nonagonal-closed-form

Three times the sum of the first n nonagonal-gnomon terms equals n(n+1)(7n-4).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Three times the sum of the first n nonagonal-gnomon terms equals n(n+1)(7n-4). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n; Finset.sum_range_succ then nlinarith over Nat subtractions. Verified to build (lake env lean).
