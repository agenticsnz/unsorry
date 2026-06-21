import Mathlib

theorem bezout_eleven_thirteen_eq_one : ∃ x y : ℤ, 11 * x + 13 * y = 1 := by
  exact ⟨6, -5, by norm_num⟩
