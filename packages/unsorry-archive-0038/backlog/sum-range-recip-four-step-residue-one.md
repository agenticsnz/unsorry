# sum-range-recip-four-step-residue-one

The sum of 4/((4k+1)(4k+5)) for k from 0 to n-1 telescopes to 1 minus 1/(4n+1).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of 4/((4k+1)(4k+5)) for k from 0 to n-1 telescopes to 1 minus 1/(4n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ; each term is 1/(4k+1) - 1/(4k+5); finish with field_simp/ring. Verified to build (lake env lean).
