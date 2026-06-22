import Mathlib

theorem pell_d5_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 5 * y ^ 2 = 1) : (9 * x + 20 * y) ^ 2 - 5 * (4 * x + 9 * y) ^ 2 = 1 := by
  linear_combination h
