import Mathlib

theorem diff_two_squares_zmod_four_ne_two (a b : ℤ) : (((a ^ 2 - b ^ 2 : ℤ)) : ZMod 4) ≠ 2 := by
  have hcast : ((a ^ 2 - b ^ 2 : ℤ) : ZMod 4) = (a : ZMod 4) ^ 2 - (b : ZMod 4) ^ 2 := by
    push_cast; ring
  rw [hcast]
  have key : ∀ u v : ZMod 4, u ^ 2 - v ^ 2 ≠ 2 := by decide
  exact key (a : ZMod 4) (b : ZMod 4)
