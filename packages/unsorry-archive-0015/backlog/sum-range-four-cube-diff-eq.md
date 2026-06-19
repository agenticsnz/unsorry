# sum-range-four-cube-diff-eq

The sum of (4k³+6k²+4k+1) for k from 0 to n-1 equals n⁴.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of (4k³+6k²+4k+1) for k from 0 to n-1 equals n⁴. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction with Finset.sum_range_succ; per-term is (k+1)⁴−k⁴, close with ring. Verified to build (lake env lean).
