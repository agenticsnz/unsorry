import Mathlib

set_option maxRecDepth 8000 in
theorem three_fourth_powers_zmod_sixteen_mem (a b c : ℤ) :
    ((a^4 + b^4 + c^4 : ℤ) : ZMod 16) ∈ ({0, 1, 2, 3} : Set (ZMod 16)) := by
  sorry
