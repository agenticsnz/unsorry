# sum-nonagonal-numbers-closed-form

Three times the running sum of the first n nonagonal numbers (as k(7k-5)) equals n(n+1)(7n-4).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** Three times the running sum of the first n nonagonal numbers (as k(7k-5)) equals n(n+1)(7n-4). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction over Finset.range with sum_range_succ; ring closes the step. Verified to build (lake env lean).
