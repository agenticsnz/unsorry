import Mathlib

theorem sum_range_cube_mul_choose (n : ℕ) :
    8 * ∑ k ∈ Finset.range (n + 1), k ^ 3 * n.choose k = n ^ 2 * (n + 3) * 2 ^ n := by
  sorry
