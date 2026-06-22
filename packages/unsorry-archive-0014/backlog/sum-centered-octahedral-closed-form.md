# sum-centered-octahedral-closed-form

The running sum of three-times-centered-octahedral terms (2k+1)(2k^2+2k+3) equals n^2(n^2+2).

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog.
- **Reference:** The running sum of three-times-centered-octahedral terms (2k+1)(2k^2+2k+3) equals n^2(n^2+2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction over Finset.range n with sum_range_succ; the quartic step is closed by ring. Verified to build (lake env lean) at sourcing.
