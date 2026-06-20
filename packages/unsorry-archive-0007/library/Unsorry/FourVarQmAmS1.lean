import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

theorem pair_sum_sq_le_two_sq_sum (x y : ℝ) : (x + y) ^ 2 ≤ 2 * (x ^ 2 + y ^ 2) := by
  nlinarith [sq_nonneg (x - y)]
