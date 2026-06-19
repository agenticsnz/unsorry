import Mathlib

theorem pell_d17_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 17 * y ^ 2 = 1) : (33 * x + 136 * y) ^ 2 - 17 * (8 * x + 33 * y) ^ 2 = 1 := by
  linear_combination h
