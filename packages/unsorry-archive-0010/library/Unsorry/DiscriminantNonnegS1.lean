import Mathlib

theorem mul_four_a_quadratic_eq_completed_square (a b c x : ℝ) : 4 * a * (a * x ^ 2 + b * x + c) = (2 * a * x + b) ^ 2 + (4 * a * c - b ^ 2) := by
  ring
