import Mathlib

theorem sum_four_sq_ge_two_cross (a b c d : ℝ) :
    2 * a * b + 2 * c * d ≤ a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (c - d)]
