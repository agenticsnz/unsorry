import Mathlib

theorem sum_two_fourth_powers_zmod_sixteen_mem (a b : ℤ) : (((a ^ 4 + b ^ 4 : ℤ)) : ZMod 16) = 0 ∨ (((a ^ 4 + b ^ 4 : ℤ)) : ZMod 16) = 1 ∨ (((a ^ 4 + b ^ 4 : ℤ)) : ZMod 16) = 2 := by
  have h : (((a ^ 4 + b ^ 4 : ℤ)) : ZMod 16) = (a : ZMod 16) ^ 4 + (b : ZMod 16) ^ 4 := by
    push_cast
    ring
  rw [h]
  generalize (a : ZMod 16) = x
  generalize (b : ZMod 16) = y
  revert x y
  decide