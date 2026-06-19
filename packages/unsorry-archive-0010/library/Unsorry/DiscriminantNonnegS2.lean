import Mathlib

theorem completed_square_form_nonneg (a b c x : ℝ) (hdisc : b ^ 2 ≤ 4 * a * c) :
    0 ≤ (2 * a * x + b) ^ 2 + (4 * a * c - b ^ 2) := by
  nlinarith [sq_nonneg (2 * a * x + b), hdisc]
