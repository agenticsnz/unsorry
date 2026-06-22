# sum-stella-octangula-closed-form

Twice the running sum of stella octangula numbers k(2k^2-1) equals n(n+1)(n^2+n-1).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog.
- **Reference:** Twice the running sum of stella octangula numbers k(2k^2-1) equals n(n+1)(n^2+n-1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; reduces to a cubic identity closed by ring (Nat subtraction valid for the indexed terms). Verified to build (lake env lean) at sourcing.
