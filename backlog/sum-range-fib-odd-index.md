# sum-range-fib-odd-index

For every natural n, ∑_{i<n} F(2i+1) = F(2n): the sum of the first n odd-indexed Fibonacci numbers F₁ + F₃ + ⋯ + F_{2n−1} equals F(2n).

- **Source:** Fibonacci identities
- **Reference:** Vajda, Fibonacci & Lucas Numbers and the Golden Section (1989), identity (5); Koshy, Fibonacci and Lucas Numbers with Applications, Thm 5.1. mathlib has single-term `Nat.fib_two_mul` and the all-index `Nat.fib_succ_eq_succ_sum`, but no odd-indexed Fibonacci sum.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 2
- **Decomposition sketch:** L1 base n=0 (both sides 0). L2 induction via `Finset.sum_range_succ`; the step uses F(2n)+F(2n+1)=F(2n+2) (`Nat.fib_add_two`). L3 simp/omega to stitch F(2(n+1)) = F(2n+2).
