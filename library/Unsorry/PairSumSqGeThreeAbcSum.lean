import Mathlib

theorem pair_sum_sq_ge_three_abc_sum (a b c : ℝ) :
    (a*b + b*c + c*a)^2 ≥ 3 * (a*b*c) * (a + b + c) := by
  nlinarith [sq_nonneg (a*b - b*c), sq_nonneg (b*c - c*a), sq_nonneg (c*a - a*b)]
