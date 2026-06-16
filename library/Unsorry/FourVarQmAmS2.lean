import Mathlib

theorem four_sum_sq_le_two_pair_sums (a b c d : ℝ) : (a + b + c + d) ^ 2 ≤ 2 * ((a + b) ^ 2 + (c + d) ^ 2) := by
  nlinarith [sq_nonneg (a + b - c - d)]
