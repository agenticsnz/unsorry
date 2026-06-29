import Mathlib

theorem pell_d13_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 13 * y ^ 2 = 1) : (649 * x + 2340 * y) ^ 2 - 13 * (180 * x + 649 * y) ^ 2 = 1 := by
  linear_combination h
