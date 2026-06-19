# alt-sum-range-sq-eq-signed-pronic

Twice the alternating sum of the first n+1 squares equals (-1)^n times the n-th pronic number n(n+1).

- **Source:** #400 Identity Engine (ADR-043) — closed-form sum family; promoted from candidate backlog.
- **Reference:** Twice the alternating sum of the first n+1 squares equals (-1)^n times the n-th pronic number n(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ; ring_nf and a parity case-split on (-1)^(n+1) per step. Verified to build (lake env lean) at sourcing.
