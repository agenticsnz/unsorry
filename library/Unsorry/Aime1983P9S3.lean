import Mathlib.Tactic

/-- For positive `y`, the expression `(9 * y ^ 2 + 4) / y` is at least `12`.

This is the key inequality behind AIME 1983 Problem 9: minimizing `9 * y + 4 / y`
over positive reals via the square `(3 * y - 2) ^ 2 ≥ 0`, with equality at `y = 2 / 3`. -/
theorem aime_1983_p9_amgm_div (y : ℝ) (hy : 0 < y) : 12 ≤ (9 * y ^ 2 + 4) / y := by
  rw [le_div_iff₀ hy]
  nlinarith [sq_nonneg (3 * y - 2)]
