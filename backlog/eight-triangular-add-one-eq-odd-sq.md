# eight-triangular-add-one-eq-odd-sq

For every natural n, 8·Tₙ + 1 = (2n+1)², where Tₙ = ∑_{i≤n} i is the n-th triangular number; the classic "8T+1 is a perfect (odd) square" test for triangular numbers.

- **Source:** classic identities (triangular-number gems — compounds on the Gauss sum)
- **Reference:** The triangular-number characterisation: m is triangular iff 8m+1 is a perfect square (the forward direction). Conway & Guy, The Book of Numbers; standard recreational/elementary number theory.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 2
- **Decomposition sketch:** Substitute the Gauss sum Tₙ = ∑_{i≤n} i = n(n+1)/2 (mathlib `Finset.sum_range_id` / `Gauss_sum`), then 8·n(n+1)/2 + 1 = 4n(n+1)+1 = (2n+1)² by ring. 1 step. **Compounds directly on the Gauss closed form.**
