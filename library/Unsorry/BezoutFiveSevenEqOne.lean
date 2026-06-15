import Mathlib

theorem bezout_five_seven_eq_one : ∃ x y : ℤ, 5 * x + 7 * y = 1 := by
  exact ⟨3, -2, by norm_num⟩
