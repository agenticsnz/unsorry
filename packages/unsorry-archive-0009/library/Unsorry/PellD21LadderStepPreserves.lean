import Mathlib

theorem pell_d21_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 21 * y ^ 2 = 1) : (55 * x + 252 * y) ^ 2 - 21 * (12 * x + 55 * y) ^ 2 = 1 := by
  linear_combination h
