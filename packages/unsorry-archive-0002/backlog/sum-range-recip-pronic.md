# sum-range-recip-pronic

For every natural n, the sum over i in 0..n-1 of 1/((i+1)(i+2)) equals n/(n+1) (over ℚ); the classic telescoping sum 1/(1·2) + 1/(2·3) + ... + 1/(n(n+1)) = n/(n+1).

- **Source:** classic identities
- **Reference:** Classic telescoping/partial-fractions identity ∑ 1/(k(k+1)) = n/(n+1); Graham, Knuth & Patashnik, Concrete Mathematics, §2.5 (partial fractions); standard first-year analysis exercise.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-12)
- **Difficulty:** 3
- **Decomposition sketch:** L1 (optional): partial-fraction lemma 1/((m+1)(m+2)) = 1/(m+1) - 1/(m+2) over ℚ. L2: induction on n with Finset.sum_range_succ; step closes by field_simp + ring (denominators (n+1), (n+2) are nonzero naturals cast to ℚ). 2 steps.
