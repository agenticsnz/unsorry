# sum-range-three-consecutive-product

For every natural n, 4·∑_{i<n} i(i+1)(i+2) = (n−1)·n·(n+1)·(n+2): the telescoping sum of products of three consecutive integers (the tetrahedral-by-4 closed form).

- **Source:** falling-factorial telescoping
- **Reference:** Graham, Knuth & Patashnik, Concrete Mathematics, §2.6 (summation by parts on falling factorials); ∑_{i=1}^{m} i(i+1)(i+2) = m(m+1)(m+2)(m+3)/4.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 2
- **Decomposition sketch:** L1 per-term telescoping identity 4·i(i+1)(i+2) = (i−1)i(i+1)(i+2) − (i−2)(i−1)i(i+1) (work in ℤ, cast to avoid ℕ-subtraction). L2 induction via `Finset.sum_range_succ`. L3 `ring`.
