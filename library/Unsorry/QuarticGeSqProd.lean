import Mathlib

theorem quartic_ge_sq_prod (a b : ℝ) : 2 * (a ^ 2 * b ^ 2) ≤ a ^ 4 + b ^ 4 := by
  nlinarith [sq_nonneg (a ^ 2 - b ^ 2)]
