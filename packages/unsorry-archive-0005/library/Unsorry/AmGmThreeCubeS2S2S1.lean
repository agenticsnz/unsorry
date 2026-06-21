import Mathlib.Data.Real.Basic

/-- The square of a real number is nonnegative, applied to `x - 2 * y`. -/
theorem weighted_am_gm_two_one_cube_factor_sq_nonneg (x y : ℝ) : 0 ≤ (x - 2 * y) ^ 2 :=
  sq_nonneg (x - 2 * y)
