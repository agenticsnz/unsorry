import Mathlib

theorem pell_d2_form_product_telescope_step (x y u v : ℤ) (h : u ^ 2 - 2 * v ^ 2 = 1) : x ^ 2 - 2 * y ^ 2 = (u * x + 2 * v * y) ^ 2 - 2 * (v * x + u * y) ^ 2 := by
  linear_combination (2 * y ^ 2 - x ^ 2) * h
