import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Ring

theorem weighted_am_gm_two_one_cube_factor_identity (x y : ℝ) : 4 * (x + y) ^ 3 - 27 * (x ^ 2 * y) = (x - 2 * y) ^ 2 * (4 * x + y) := by
  ring
