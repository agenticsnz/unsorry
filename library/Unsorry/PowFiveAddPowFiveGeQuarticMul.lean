import Mathlib

theorem pow_five_add_pow_five_ge_quartic_mul (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) : a ^ 4 * b + a * b ^ 4 ≤ a ^ 5 + b ^ 5 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (a + b), mul_nonneg ha hb,
    sq_nonneg (a ^ 2 - b ^ 2), mul_nonneg (mul_nonneg ha hb) (sq_nonneg (a - b)),
    mul_nonneg (add_nonneg ha hb) (sq_nonneg (a - b)),
    mul_nonneg (mul_nonneg (add_nonneg ha hb) (add_nonneg (sq_nonneg a) (sq_nonneg b))) (sq_nonneg (a - b))]