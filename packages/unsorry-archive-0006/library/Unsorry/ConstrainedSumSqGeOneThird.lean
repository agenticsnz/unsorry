import Mathlib

theorem constrained_sum_sq_ge_one_third (a b c : ℝ) (h : a + b + c = 1) : 1 / 3 ≤ a ^ 2 + b ^ 2 + c ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a), h]
