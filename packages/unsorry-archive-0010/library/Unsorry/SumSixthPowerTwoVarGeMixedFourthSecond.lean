import Mathlib

theorem sum_sixth_power_two_var_ge_mixed_fourth_second (a b : ℝ) : a ^ 6 + b ^ 6 ≥ a ^ 4 * b ^ 2 + a ^ 2 * b ^ 4 := by
  nlinarith [mul_nonneg (sq_nonneg (a ^ 2 - b ^ 2)) (add_nonneg (sq_nonneg a) (sq_nonneg b))]
