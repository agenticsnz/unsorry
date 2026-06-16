import Mathlib

theorem pell_d10_fundamental_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 10 * y ^ 2 = 1) : (19 * x + 60 * y) ^ 2 - 10 * (6 * x + 19 * y) ^ 2 = 1 := by
  linear_combination h
