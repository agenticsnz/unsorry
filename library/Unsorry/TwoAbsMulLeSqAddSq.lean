import Mathlib

theorem two_abs_mul_le_sq_add_sq (a b : ℝ) : 2 * |a * b| ≤ a ^ 2 + b ^ 2 := by
  rcases le_total 0 (a * b) with h | h
  · rw [abs_of_nonneg h]
    nlinarith [sq_nonneg (a - b)]
  · rw [abs_of_nonpos h]
    nlinarith [sq_nonneg (a + b)]
