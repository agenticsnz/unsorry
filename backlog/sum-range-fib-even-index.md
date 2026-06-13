# sum-range-fib-even-index

For every natural n, ∑_{i<n} F(2(i+1)) = F(2n+1) − 1: the sum of the first n even-indexed Fibonacci numbers F₂ + F₄ + ⋯ + F_{2n} equals F(2n+1) − 1.

- **Source:** Fibonacci identities
- **Reference:** Vajda (1989), identity (6); Koshy, Thm 5.2. Companion to the odd-index sum `sum-range-fib-odd-index`, whose result it can reuse.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 3
- **Decomposition sketch:** L1 ℕ-subtraction guard F(2n+1) ≥ 1. L2 reuse `sum-range-fib-odd-index`, or induct with `Finset.sum_range_succ` and F(2n+1)+F(2n+2)=F(2n+3). L3 omega to discharge the truncated subtraction.
