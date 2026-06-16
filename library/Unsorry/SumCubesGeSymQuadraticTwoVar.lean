import Mathlib

theorem sum_cubes_ge_sym_quadratic_two_var (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) : a ^ 2 * b + a * b ^ 2 ≤ a ^ 3 + b ^ 3 := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (add_nonneg ha hb)]
