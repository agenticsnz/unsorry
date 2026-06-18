import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

/-- A linear nonnegativity fact: for nonnegative reals `x` and `y`,
the combination `4 * x + y` is nonnegative. -/
theorem weighted_am_gm_two_one_cube_factor_lin_nonneg (x y : ℝ) (hx : 0 ≤ x) (hy : 0 ≤ y) :
    0 ≤ 4 * x + y := by
  linarith
