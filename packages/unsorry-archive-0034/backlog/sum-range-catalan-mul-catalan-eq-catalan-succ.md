# sum-range-catalan-mul-catalan-eq-catalan-succ

The Catalan numbers satisfy the convolution recurrence: the self-convolution of the first n+1 Catalan numbers gives C(n+1).

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog.
- **Reference:** The Catalan numbers satisfy the convolution recurrence: the self-convolution of the first n+1 Catalan numbers gives C(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Rewrite catalan_succ (a Fin-indexed convolution) as a Finset.range sum via Fin.sum_univ_eq_sum_range and Nat.sub bookkeeping. Verified to build (lake env lean) at sourcing.
