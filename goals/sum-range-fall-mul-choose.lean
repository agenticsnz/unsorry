import Mathlib

theorem sum_range_fall_mul_choose (n : ℕ) :
    4 * ∑ k ∈ Finset.range (n + 1), k * (k - 1) * n.choose k = n * (n - 1) * 2 ^ n := by
  sorry
