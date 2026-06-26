import Mathlib

theorem pell_d3_no_small_nontrivial_y (x y : ℤ) (h : x ^ 2 - 3 * y ^ 2 = 1) (hy : 0 < y) (hx : 0 ≤ x) : 1 ≤ y ∧ 2 ≤ x := by
  have hy1 : 1 ≤ y := by omega
  refine ⟨hy1, ?_⟩
  nlinarith [h, hy1, hx, sq_nonneg (y - 1)]
