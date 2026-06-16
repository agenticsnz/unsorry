import Mathlib

theorem pow_four_add_pow_four_ge_cube_mul (a b : ℝ) : a ^ 3 * b + a * b ^ 3 ≤ a ^ 4 + b ^ 4 := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (sq_nonneg a), mul_nonneg (sq_nonneg (a - b)) (sq_nonneg b), mul_nonneg (sq_nonneg (a - b)) (sq_nonneg (a + b))]
