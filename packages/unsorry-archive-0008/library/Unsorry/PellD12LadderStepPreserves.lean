import Mathlib

theorem pell_d12_ladder_step_preserves (x y : ℤ) (h : x ^ 2 - 12 * y ^ 2 = 1) : (7 * x + 24 * y) ^ 2 - 12 * (2 * x + 7 * y) ^ 2 = 1 := by
  linear_combination h
