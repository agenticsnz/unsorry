import Mathlib

theorem add_sq_ge_four_mul_real (a b : ℝ) : 4 * (a * b) ≤ (a + b) ^ 2 := by
  nlinarith [sq_nonneg (a - b)]
