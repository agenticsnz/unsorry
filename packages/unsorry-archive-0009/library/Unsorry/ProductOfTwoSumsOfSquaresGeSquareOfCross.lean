import Mathlib

theorem product_of_two_sums_of_squares_ge_square_of_cross (x y z w : ℝ) : (x ^ 2 + y ^ 2) * (z ^ 2 + w ^ 2) ≥ (x * w - y * z) ^ 2 := by
  nlinarith [sq_nonneg (x * z + y * w)]
