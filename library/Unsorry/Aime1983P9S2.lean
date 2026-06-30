import Mathlib.Tactic

/-- For all real `y`, `12 * y ≤ 9 * y ^ 2 + 4`, since the difference is `(3 * y - 2) ^ 2 ≥ 0`. -/
theorem aime_1983_p9_amgm_cleared (y : ℝ) : 12 * y ≤ 9 * y ^ 2 + 4 := by
  nlinarith [sq_nonneg (3 * y - 2)]
