import Mathlib

theorem pell_d2_square_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) : (17 * x + 24 * y) ^ 2 - 2 * (12 * x + 17 * y) ^ 2 = 1 := by
  linear_combination h
