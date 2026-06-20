# sum-rhombic-dodecahedral-eq-fourth-power

The running sum of the rhombic-dodecahedral gnomons (2k-1)(2k^2-2k+1) equals n^4 exactly.

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog.
- **Reference:** The running sum of the rhombic-dodecahedral gnomons (2k-1)(2k^2-2k+1) equals n^4 exactly. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; the k=0 term vanishes and the gnomon (n+1)^4 - n^4 expansion is closed by ring after Nat-subtraction care. Verified to build (lake env lean) at sourcing.
