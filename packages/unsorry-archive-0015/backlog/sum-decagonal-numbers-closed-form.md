# sum-decagonal-numbers-closed-form

Six times the running sum of the first n decagonal numbers k(4k-3) equals n(n+1)(8n-5).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog.
- **Reference:** Six times the running sum of the first n decagonal numbers k(4k-3) equals n(n+1)(8n-5). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ then ring; factor of 6 clears the /2. Verified to build (lake env lean) at sourcing.
