import Mathlib

theorem pell_d5_positive_from_negative_square (x y : ℤ) (h : x^2 - 5*y^2 = -1) :
    (x^2 + 5*y^2)^2 - 5*(2*x*y)^2 = 1 := by
  linear_combination (x ^ 2 - 5 * y ^ 2 - 1) * h
