import Mathlib

theorem pell_d2_x_sub_y_times_x_add_y (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) : (x - y) * (x + y) = y ^ 2 + 1 := by
  linear_combination h
