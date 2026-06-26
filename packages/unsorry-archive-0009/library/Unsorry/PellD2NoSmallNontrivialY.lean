import Mathlib

theorem pell_d2_no_small_nontrivial_y (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) (hy : 0 < y) : 2 ≤ y := by
  by_contra hlt
  have hy1 : y = 1 := by omega
  subst hy1
  simp only [one_pow, mul_one] at h
  have hx3 : x ^ 2 = 3 := by omega
  have key : ∀ a : ZMod 4, a ^ 2 ≠ 3 := by decide
  apply key (x : ZMod 4)
  have hc := congrArg (fun t : ℤ => (t : ZMod 4)) hx3
  push_cast at hc
  exact hc
