import Mathlib

theorem two_var_sq_add_one_ge_cross_plus_sum (a b : ℝ) : a * b + a + b ≤ a ^ 2 + b ^ 2 + 1 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (a - 1), sq_nonneg (b - 1)]
