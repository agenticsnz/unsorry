import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-nine-ne-six`: over `ℤ`, `a^2 + b^2` is never `6` in `ZMod 9`,
by reducing the integer cast to `ZMod 9` and a finite case check. -/
theorem sum_two_squares_zmod_nine_ne_six (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 9) ≠ 6 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 9)
      = (a : ZMod 9) ^ 2 + (b : ZMod 9) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 9) = x
  generalize (b : ZMod 9) = y
  revert x y
  decide
