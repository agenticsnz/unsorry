import Mathlib

theorem prod_pair_sums_ge_eight_mul (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) : 8 * (a * b * c) ≤ (a + b) * (b + c) * (c + a) := by
  nlinarith [mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (c - a)), mul_nonneg hc (sq_nonneg (a - b))]
