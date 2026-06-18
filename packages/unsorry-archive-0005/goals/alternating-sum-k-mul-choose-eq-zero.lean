import Mathlib

theorem alternating_sum_k_mul_choose_eq_zero (n : ℕ) (hn : 2 ≤ n) : ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (k * n.choose k) = 0 := by
  sorry
