import Mathlib

theorem pell_d2_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) : (3 * x + 4 * y) ^ 2 - 2 * (2 * x + 3 * y) ^ 2 = 1 := by
  linear_combination h
