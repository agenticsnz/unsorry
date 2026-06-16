import Mathlib

theorem square_of_sum_ge_three_pairwise (a b c : ℝ) : 3 * (a * b + b * c + c * a) ≤ (a + b + c) ^ 2 := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a)]
