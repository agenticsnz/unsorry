import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

/-- If `a > 0` and `0 ≤ 4 * a * y`, then `0 ≤ y`. -/
theorem nonneg_of_pos_mul_four_a_nonneg (a y : ℝ) (ha : 0 < a) (h : 0 ≤ 4 * a * y) :
    0 ≤ y := by
  nlinarith [mul_pos (by norm_num : (0 : ℝ) < 4) ha]
