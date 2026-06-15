import Mathlib

theorem sq_lt_cube_of_one_lt (x : ℝ) (hx : 1 < x) : x ^ 2 < x ^ 3 := by
  have hx0 : (0 : ℝ) < x := by linarith
  nlinarith [mul_pos (mul_pos hx0 hx0) (by linarith : (0 : ℝ) < x - 1)]
