import Mathlib

theorem sum_sq_ge_third_sq_sum (a b c : ℝ) : (a + b + c) ^ 2 / 3 ≤ a ^ 2 + b ^ 2 + c ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a)]
