# sum-range-choose-mul-choose-three-eq

Eight times the subset-of-a-subset sum of C(n,k)·C(k,3) equals C(n,3)·2^n.

- **Source:** #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610).
- **Reference:** Eight times the subset-of-a-subset sum of C(n,k)·C(k,3) equals C(n,3)·2^n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Subset-of-subset identity C(n,k)C(k,3)=C(n,3)C(n-3,k-3), factor out C(n,3), then sum the shifted row to 2^(n-3). Verified to build (lake env lean).
