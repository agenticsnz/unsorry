import Mathlib

theorem one_add_three_x_le_cube (x : ℝ) (hx : 0 ≤ x) : 1 + 3 * x ≤ (1 + x) ^ 3 := by
  nlinarith [sq_nonneg x, mul_nonneg hx (sq_nonneg x)]
