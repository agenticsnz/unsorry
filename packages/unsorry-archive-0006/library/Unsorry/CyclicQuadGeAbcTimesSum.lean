import Mathlib

theorem cyclic_quad_ge_abc_times_sum (a b c : ℝ) : a * b * c * (a + b + c) ≤ a ^ 2 * b ^ 2 + b ^ 2 * c ^ 2 + c ^ 2 * a ^ 2 := by
  nlinarith [sq_nonneg (a * b - b * c), sq_nonneg (b * c - c * a), sq_nonneg (c * a - a * b)]
