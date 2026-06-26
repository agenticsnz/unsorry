import Mathlib

theorem pairwise_product_sum_sq_ge_three_abc_sum (a b c : ℝ) : 3 * (a * b * c * (a + b + c)) ≤ (a * b + b * c + c * a) ^ 2 := by
  nlinarith [sq_nonneg (a * b - b * c), sq_nonneg (b * c - c * a), sq_nonneg (c * a - a * b)]
