import Mathlib

theorem sum_sq_norm_sq_le_twice_sum_fourth (a b : ℝ) : (a ^ 2 + b ^ 2) ^ 2 ≤ 2 * (a ^ 4 + b ^ 4) := by
  nlinarith [sq_nonneg (a ^ 2 - b ^ 2)]
