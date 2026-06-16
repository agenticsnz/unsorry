import Mathlib

theorem pell_d2_negative_to_positive_step (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = -1) : (x + 2 * y) ^ 2 - 2 * (x + y) ^ 2 = 1 := by
  linear_combination -h
