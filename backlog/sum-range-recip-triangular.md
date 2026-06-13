# sum-range-recip-triangular

For every natural n, ∑_{k<n} 2/((k+1)(k+2)) = 2n/(n+1) over ℚ: the reciprocals of the triangular numbers telescope (∑ 1/T_k → 2).

- **Source:** telescoping series (reciprocals of triangular numbers)
- **Reference:** Standard telescoping series; the sum of reciprocals of all triangular numbers is 2. Companion to `sum-range-recip-pronic` (1/(k(k+1))) already in the library, sharing the partial-fraction machinery over ℚ.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 3
- **Decomposition sketch:** L1 partial fractions 2/((k+1)(k+2)) = 2/(k+1) − 2/(k+2). L2 `Finset.sum_range_succ` induction (telescoping). L3 `field_simp` + `ring` at the step (denominators nonzero in ℚ) to reach 2n/(n+1).
