import Mathlib

theorem pell_d2_y_lt_x_of_pos (x y : ℤ) (hx : 0 < x) (hy : 0 < y) (h : x ^ 2 - 2 * y ^ 2 = 1) : y < x := by
  have h1 : x^2 = 2*y^2 + 1 := by
    linarith
  have h2 : 2*y^2 + 1 > y^2 := by
    nlinarith [sq_pos_of_pos hy]
  have h3 : x^2 > y^2 := by
    rw [h1]
    exact h2
  nlinarith [sq_nonneg (x - y), sq_nonneg (x + y)]