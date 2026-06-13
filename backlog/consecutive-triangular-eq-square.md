# consecutive-triangular-eq-square

For every natural n, Tₙ + Tₙ₋₁ = n², where Tₙ = ∑_{i≤n} i; the sum of two consecutive triangular numbers is a perfect square.

- **Source:** classic identities (triangular-number gems — compounds on the Gauss sum)
- **Reference:** Theon of Smyrna's classical observation that consecutive triangular numbers sum to a square (Tₙ₋₁ + Tₙ = n²). Conway & Guy, The Book of Numbers; Heath, A History of Greek Mathematics.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 2
- **Decomposition sketch:** Tₙ = ∑_{i≤n} i = n(n+1)/2 and Tₙ₋₁ = ∑_{i<n} i = (n−1)n/2 (Gauss); their sum = n(n+1)/2 + n(n−1)/2 = n² by ring. The n=0 case (empty second sum) closes trivially. 1 step.
