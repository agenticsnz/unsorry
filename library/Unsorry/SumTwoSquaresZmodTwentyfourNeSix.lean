import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-twentyfour-ne-six`: over `ℤ`, `a ^ 2 + b ^ 2` is never `6` in `ZMod 24`,
by reducing the integer cast to `ZMod 24` and a finite case check. -/
theorem sum_two_squares_zmod_twentyfour_ne_six (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 24) ≠ 6 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 24) = (a : ZMod 24) ^ 2 + (b : ZMod 24) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 24) = x
  generalize (b : ZMod 24) = y
  revert x y
  decide
