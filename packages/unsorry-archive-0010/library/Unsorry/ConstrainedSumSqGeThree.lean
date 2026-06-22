import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

/-- If three real numbers sum to `3`, the sum of their squares is at least `3`.

The slack equals `((a-b)^2 + (b-c)^2 + (a-c)^2) / 3`, which is a sum of squares
and hence nonnegative; `nlinarith` closes the goal from those three witnesses
together with the linear constraint. -/
theorem constrained_sum_sq_ge_three (a b c : ℝ) (h : a + b + c = 3) :
    3 ≤ a ^ 2 + b ^ 2 + c ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (a - c), h]
