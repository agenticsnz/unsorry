# prod-one-sub-inv-sq-telescope

For n ≥ 2, ∏_{k=2}^{n} (1 − 1/k²) = (n+1)/(2n) over ℚ — the telescoping product of (1 − 1/k²).

- **Source:** Classic telescoping product (Wallis-adjacent finite product)
- **Reference:** ∏(1−1/k²) = (n+1)/(2n), via the factorisation 1 − 1/k² = (k−1)(k+1)/k². Distinct from the reciprocal-pronic / reciprocal-triangular SUM telescopes already in the pool (this is a multiplicative, rational telescope).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035)
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14)
- **Difficulty:** 4
- **Decomposition sketch:** L1 base n=2: 1 − 1/4 = 3/4 = 3/(2·2). L2 `Finset.prod_Icc_succ_top` peels the (n+1) factor. L3 rewrite 1 − 1/(n+1)² = n(n+2)/(n+1)². L4 substitute IH and close with `field_simp` + `ring` (discharge (n:ℚ) ≠ 0). Multiplicative rational telescoping — no single battery tactic closes it.
