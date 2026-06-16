import Mathlib

theorem amgm_prod_half_sum_le_cubes (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) : 2 * (a * b * (a + b)) ≤ a ^ 3 + b ^ 3 + a ^ 3 + b ^ 3 := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (add_nonneg ha hb)]
