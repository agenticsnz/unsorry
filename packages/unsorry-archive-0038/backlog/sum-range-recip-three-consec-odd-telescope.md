# sum-range-recip-three-consec-odd-telescope

The sum of 1/((2k+1)(2k+3)(2k+5)) over the first n terms equals 1/12 minus 1/(4(2n+1)(2n+3)).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of 1/((2k+1)(2k+3)(2k+5)) over the first n terms equals 1/12 minus 1/(4(2n+1)(2n+3)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Summand = 1/4[1/((2k+1)(2k+3)) - 1/((2k+3)(2k+5))]; induction with Finset.sum_range_succ, field_simp on positive odd factors, ring. Verified to build (lake env lean).
