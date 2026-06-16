import Mathlib

theorem quad_form_ge_three_quarter_sq (a b : ℝ) : 3 / 4 * (a + b) ^ 2 ≤ a ^ 2 + a * b + b ^ 2 := by
  nlinarith [sq_nonneg (a - b)]
