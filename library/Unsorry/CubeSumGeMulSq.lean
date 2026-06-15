import Mathlib

theorem cube_sum_ge_mul_sq (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) :
    a ^ 2 * b + a * b ^ 2 ≤ a ^ 3 + b ^ 3 := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (add_nonneg ha hb)]
