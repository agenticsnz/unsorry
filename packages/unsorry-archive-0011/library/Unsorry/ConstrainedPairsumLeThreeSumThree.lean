import Mathlib

theorem constrained_pairsum_le_three_sum_three (a b c : ℝ) (h : a + b + c = 3) : a * b + b * c + c * a ≤ 3 := by
  have h1 : (a - b)^2 + (b - c)^2 + (c - a)^2 ≥ 0 := by
    nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a)]
  have h2 : a^2 + b^2 + c^2 ≥ 3 := by
    have h_sq : a^2 + b^2 + c^2 ≥ (a + b + c)^2 / 3 := by
      nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a)]
    rw [h] at h_sq
    linarith
  have h3 : (a + b + c)^2 = a^2 + b^2 + c^2 + 2 * (a * b + b * c + c * a) := by
    ring
  rw [h] at h3
  linarith