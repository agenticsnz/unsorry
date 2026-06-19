# sum-range-two-k-add-one-div-two-pow-closed

The sum of (2k+1)/2^k over the first n terms equals 6 minus (4n+6)/2^n.

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The sum of (2k+1)/2^k over the first n terms equals 6 minus (4n+6)/2^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n with Finset.sum_range_succ; rewrite 2^(k+1)=2·2^k (pow_succ), field_simp using 2^k ≠ 0, then ring. Verified to build (lake env lean).
