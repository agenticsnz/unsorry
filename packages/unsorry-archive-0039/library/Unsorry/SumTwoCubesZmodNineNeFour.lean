import Mathlib

theorem sum_two_cubes_zmod_nine_ne_four (m n : ℤ) : (((m ^ 3 + n ^ 3 : ℤ)) : ZMod 9) ≠ 4 := by
  intro h
  push_cast at h
  have : ((m : ZMod 9) ^ 3 + (n : ZMod 9) ^ 3) = 4 := h
  have key : ∀ a b : ZMod 9, a ^ 3 + b ^ 3 ≠ 4 := by decide
  exact key _ _ this