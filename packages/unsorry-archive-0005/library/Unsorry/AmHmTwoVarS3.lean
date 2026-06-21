import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-- For positive reals `a` and `b`, the sum of reciprocals equals the sum over the product. -/
theorem inv_add_inv_eq_add_div_mul_of_pos (a b : ℝ) (ha : 0 < a) (hb : 0 < b) :
    1 / a + 1 / b = (a + b) / (a * b) := by
  have ha' : a ≠ 0 := ne_of_gt ha
  have hb' : b ≠ 0 := ne_of_gt hb
  field_simp
  ring
