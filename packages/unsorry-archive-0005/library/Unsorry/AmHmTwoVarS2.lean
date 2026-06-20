import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

theorem four_div_add_le_add_div_mul_of_pos (a b : ℝ) (ha : 0 < a) (hb : 0 < b) : 4 / (a + b) ≤ (a + b) / (a * b) := by
  have hab : 0 < a * b := mul_pos ha hb
  have hab_add : 0 < a + b := add_pos ha hb
  rw [div_le_div_iff₀ hab_add hab]
  have h : 0 ≤ (a - b)^2 := sq_nonneg (a - b)
  linarith
