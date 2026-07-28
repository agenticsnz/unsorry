import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

/-- Cleared-denominator AM-GM step for AIME 1983 Problem 9: for every real `y`,
`12 * y ≤ 9 * y ^ 2 + 4`, which is `(3 * y - 2) ^ 2 ≥ 0` rearranged. -/
theorem aime_1983_p9_amgm_cleared (y : ℝ) : 12 * y ≤ 9 * y ^ 2 + 4 := by
  nlinarith [sq_nonneg (3 * y - 2)]
