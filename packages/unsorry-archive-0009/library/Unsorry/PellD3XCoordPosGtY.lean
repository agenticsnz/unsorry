import Mathlib

theorem pell_d3_x_coord_pos_gt_y (x y : ℤ) (h : x ^ 2 - 3 * y ^ 2 = 1) (hy : 0 < y) (hx : 0 < x) : y < x := by
  nlinarith [h, hx, hy, mul_pos hx hy, sq_nonneg (x - y), sq_nonneg (x + y)]
