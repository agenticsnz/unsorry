# sum-centered-tetrahedral-closed-form

Twice the running sum of (2k+1)(k^2+k+3) equals n^2(n^2+5), a centered-tetrahedral closed form.

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog.
- **Reference:** Twice the running sum of (2k+1)(k^2+k+3) equals n^2(n^2+5), a centered-tetrahedral closed form. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; the doubling clears /2 and ring finishes the quartic step. Verified to build (lake env lean) at sourcing.
