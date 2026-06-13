# sum-range-cube-mul-choose

For every natural n, 8·(sum of k³·C(n,k) for k in 0..n) = n²(n+3)·2ⁿ; the third binomial moment ∑k³C(n,k) = n²(n+3)2^(n−3).

- **Source:** classic identities (binomial-moment tower — compounds on the proved `sum-range-sq-mul-choose`)
- **Reference:** The third moment of the binomial distribution scaled by 2ⁿ; Graham, Knuth & Patashnik, Concrete Mathematics, Ch. 5 (binomial coefficients / generating-function moments); Riordan, Combinatorial Identities.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 3
- **Decomposition sketch:** One power up from the proved `sum-range-sq-mul-choose` (4∑k²C(n,k) = n(n+1)2ⁿ). Write k³ = k·k², use the absorption identity k·C(n,k) = n·C(n−1,k−1), reindex, or induct with `Finset.sum_range_succ` and Pascal's rule; close the resulting polynomial-in-n identity by ring. 2–3 steps.
