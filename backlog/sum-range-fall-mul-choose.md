# sum-range-fall-mul-choose

For every natural n, 4·(sum of k(k−1)·C(n,k) for k in 0..n) = n(n−1)·2ⁿ; the second falling-factorial moment ∑k(k−1)C(n,k) = n(n−1)2^(n−2).

- **Source:** classic identities (binomial-moment tower)
- **Reference:** Second factorial moment of the binomial distribution; from double absorption k(k−1)C(n,k) = n(n−1)C(n−2,k−2). Graham, Knuth & Patashnik, Concrete Mathematics, Ch. 5.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); mathlib has the first moment `Nat.sum_range_mul_choose` (∑k·C(n,k)) but not this falling-factorial moment.
- **Difficulty:** 3
- **Decomposition sketch:** Twofold absorption: k(k−1)·C(n,k) = n(n−1)·C(n−2,k−2); sum over k reindexes to n(n−1)·∑C(n−2,j) = n(n−1)·2^(n−2). Or induct with Pascal's rule and close by ring. The k(k−1) over ℕ is 0 for k ∈ {0,1} (no truncation issue). 2 steps.
