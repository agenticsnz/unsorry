import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.Linarith

/--
If the symmetric quantity `a * b + b * c + c * a` is positive and the bound
`3 * (a * b + b * c + c * a) ≤ (a + b + c) ^ 2` holds, then
`3 / 2 ≤ (a + b + c) ^ 2 / (2 * (a * b + b * c + c * a))`.

Since the denominator is positive, the conclusion is equivalent to the
hypothesised bound after clearing the division.
-/
theorem symmetric_bound_implies_three_halves (a b c : ℝ) (hpos : 0 < a * b + b * c + c * a) (hineq : 3 * (a * b + b * c + c * a) ≤ (a + b + c) ^ 2) : 3 / 2 ≤ (a + b + c) ^ 2 / (2 * (a * b + b * c + c * a)) := by
  have hden : (0 : ℝ) < 2 * (a * b + b * c + c * a) := by linarith
  rw [le_div_iff₀ hden]
  linarith
