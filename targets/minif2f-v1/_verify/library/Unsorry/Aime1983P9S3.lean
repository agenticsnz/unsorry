import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

/-!
AIME 1983 Problem 9, step 3: for a positive real `y`, the quotient
`(9 * y ^ 2 + 4) / y` is at least `12`.

Multiplying through by the positive denominator reduces the claim to
`12 * y ≤ 9 * y ^ 2 + 4`, which is the AM–GM inequality for `9 * y ^ 2`
and `4`; it follows from `0 ≤ (3 * y - 2) ^ 2`.
-/

theorem aime_1983_p9_amgm_div (y : ℝ) (hy : 0 < y) : 12 ≤ (9 * y ^ 2 + 4) / y := by
  rw [le_div_iff₀ hy]
  nlinarith [sq_nonneg (3 * y - 2)]
