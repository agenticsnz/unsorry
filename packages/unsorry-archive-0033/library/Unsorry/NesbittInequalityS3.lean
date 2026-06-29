import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic

-- | Theorem: For positive real numbers a, b, and c, the sum a * b + b * c + c * a is also positive.
theorem positive_pairwise_sum (a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) : 0 < a * b + b * c + c * a := by
  have hab : 0 < a * b := mul_pos ha hb
  have hbc : 0 < b * c := mul_pos hb hc
  have hca : 0 < c * a := mul_pos hc ha
  exact add_pos (add_pos hab hbc) hca