import Mathlib

theorem quartic_ge_cross (a b : ℝ) : a ^ 3 * b + a * b ^ 3 ≤ a ^ 4 + b ^ 4 := by
  have h : (0 : ℝ) ≤ a ^ 2 + a * b + b ^ 2 := by
    nlinarith [sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]
  nlinarith [mul_nonneg (sq_nonneg (a - b)) h]
