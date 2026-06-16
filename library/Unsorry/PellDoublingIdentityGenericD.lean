import Mathlib

theorem pell_doubling_identity_generic_d (d a b : ℤ) (h : a ^ 2 - d * b ^ 2 = 1) : (a ^ 2 + d * b ^ 2) ^ 2 - d * (2 * a * b) ^ 2 = 1 := by
  linear_combination (a ^ 2 - d * b ^ 2 + 1) * h
