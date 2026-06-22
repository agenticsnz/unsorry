import Mathlib

theorem pell_d6_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 6 * y ^ 2 = 1) : (5 * x + 12 * y) ^ 2 - 6 * (2 * x + 5 * y) ^ 2 = 1 := by
  linear_combination h
