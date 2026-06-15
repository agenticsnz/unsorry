import Mathlib

theorem one_add_two_x_le_sq (x : ℝ) : 1 + 2 * x ≤ (1 + x) ^ 2 := by
  nlinarith [sq_nonneg x]
