import Mathlib

theorem pell_d11_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 11 * y ^ 2 = 1) : (10 * x + 33 * y) ^ 2 - 11 * (3 * x + 10 * y) ^ 2 = 1 := by
  linear_combination h
