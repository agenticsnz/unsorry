import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

theorem amgm_four_cross_three_var (a b c : ℝ) :
    a ^ 2 * b ^ 2 + b ^ 2 * c ^ 2 + c ^ 2 * a ^ 2 ≤ a ^ 4 + b ^ 4 + c ^ 4 := by
  nlinarith [sq_nonneg (a ^ 2 - b ^ 2), sq_nonneg (b ^ 2 - c ^ 2),
    sq_nonneg (c ^ 2 - a ^ 2)]
