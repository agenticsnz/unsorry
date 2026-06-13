# cube-eq-triangular-sq-diff

For every natural n, Tₙ₋₁² + n³ = Tₙ², where Tₙ = ∑_{i≤n} i; equivalently n³ = Tₙ² − Tₙ₋₁², the per-term form of Nicomachus's theorem (the n-th cube is the n-th difference of squared triangular numbers).

- **Source:** classic identities (triangular-number gems — the term-wise Nicomachus; compounds on `nicomachus-sum-cubes`)
- **Reference:** The telescoping core of Nicomachus's identity ∑k³ = (∑k)² = Tₙ²: each cube n³ = Tₙ² − Tₙ₋₁². Conway & Guy, The Book of Numbers; Mathematics in Lean §5 (the Nicomachus exercise).
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 2
- **Decomposition sketch:** Tₙ = Tₙ₋₁ + n, so Tₙ² − Tₙ₋₁² = (Tₙ₋₁ + n)² − Tₙ₋₁² = 2n·Tₙ₋₁ + n²; with Tₙ₋₁ = (n−1)n/2 (Gauss) this is n²(n−1) + n² = n³ by ring. Reuses the proved `nicomachus-sum-cubes` as the global statement this refines. 1–2 steps.
