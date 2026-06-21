import Mathlib

theorem cyclic_sum_sq_nonneg (a b c : ℝ) : 0 ≤ (a - b) ^ 2 + (b - c) ^ 2 + (c - a) ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a)]