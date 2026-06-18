import Mathlib

theorem abc_nine_le_sum_times_pairsum (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) : 9 * (a * b * c) ≤ (a + b + c) * (a * b + b * c + c * a) := by
  nlinarith [mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (c - a)), mul_nonneg hc (sq_nonneg (a - b))]
