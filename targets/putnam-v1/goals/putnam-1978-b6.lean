import Mathlib

open Set Real Filter Topology Polynomial

theorem putnam_1978_b6 (a : ℕ → ℕ → ℝ)
(ha : ∀ i j, a i j ∈ Icc 0 1)
(m n : ℕ)
(mnpos : m > 0 ∧ n > 0)
: ((∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 (m * i), a i j / i) ^ 2 ≤ 2 * m * ∑ i ∈ Finset.Icc 1 n, ∑ j ∈ Finset.Icc 1 (m * i), a i j) := by
  sorry
