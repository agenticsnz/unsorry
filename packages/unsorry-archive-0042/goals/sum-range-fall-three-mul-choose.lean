import Mathlib

theorem sum_range_fall_three_mul_choose (n : ℕ) : 8 * ∑ k ∈ Finset.range (n + 1), k * (k - 1) * (k - 2) * n.choose k = n * (n - 1) * (n - 2) * 2 ^ n := by
  sorry
