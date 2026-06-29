import Mathlib

theorem tangent_line_cube_trick (x : ℝ) (hx : 0 ≤ x) : 3 * x ≤ x ^ 3 + 2 := by
  nlinarith [sq_nonneg (x - 1), sq_nonneg (x + 1), mul_nonneg hx (sq_nonneg (x - 1))]