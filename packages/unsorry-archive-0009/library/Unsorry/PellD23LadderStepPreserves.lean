import Mathlib

theorem pell_d23_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 23 * y ^ 2 = 1) : (24 * x + 115 * y) ^ 2 - 23 * (5 * x + 24 * y) ^ 2 = 1 := by
  linear_combination h
