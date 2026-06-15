import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Ring

/-- Multiplying a quadratic `a * x ^ 2 + b * x + c` by `4 * a` yields the
completed-square form `(2 * a * x + b) ^ 2 + (4 * a * c - b ^ 2)`. -/
theorem mul_four_a_quadratic_eq_completed_square (a b c x : ℝ) :
    4 * a * (a * x ^ 2 + b * x + c) = (2 * a * x + b) ^ 2 + (4 * a * c - b ^ 2) := by
  ring
