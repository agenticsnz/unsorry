import Mathlib

set_option linter.unusedVariables false in
theorem sum_fourth_powers_ge_cube_times_sum (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) : a^3 * b + a * b^3 ≤ a^4 + b^4 := by
  nlinarith [mul_nonneg (sq_nonneg (a - b)) (sq_nonneg a), mul_nonneg (sq_nonneg (a - b)) (sq_nonneg b), mul_nonneg (sq_nonneg (a - b)) (sq_nonneg (a + b))]
