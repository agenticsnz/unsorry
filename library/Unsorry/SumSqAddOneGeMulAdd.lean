import Mathlib

theorem sum_sq_add_one_ge_mul_add (x y : ℝ) : x*y + x + y ≤ x^2 + y^2 + 1 := by
  nlinarith [sq_nonneg (x - y), sq_nonneg (x - 1), sq_nonneg (y - 1)]
