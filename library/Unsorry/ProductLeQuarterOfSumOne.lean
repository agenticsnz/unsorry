import Mathlib

theorem product_le_quarter_of_sum_one (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hab : a + b = 1) : a * b ≤ 1 / 4 := by
  nlinarith [sq_nonneg (a - b), hab]
