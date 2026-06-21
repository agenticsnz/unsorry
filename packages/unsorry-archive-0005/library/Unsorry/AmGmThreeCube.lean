import Mathlib

theorem am_gm_three_cube (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) : 27 * (a * b * c) ≤ (a + b + c) ^ 3 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (a - c),
    mul_nonneg ha hb, mul_nonneg hb hc, mul_nonneg ha hc,
    mul_nonneg (mul_nonneg ha hb) hc,
    mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (a - c)),
    mul_nonneg hc (sq_nonneg (a - b))]