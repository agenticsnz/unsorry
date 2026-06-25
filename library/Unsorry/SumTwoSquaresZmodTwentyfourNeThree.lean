import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-twentyfour-ne-three`: over `ℤ`, `a ^ 2 + b ^ 2` is never `3` in `ZMod 24`,
by reducing the integer cast to `ZMod 24` and a finite case check. -/
theorem sum_two_squares_zmod_twentyfour_ne_three (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 24) ≠ 3 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 24) = (a : ZMod 24) ^ 2 + (b : ZMod 24) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 24) = x
  generalize (b : ZMod 24) = y
  revert x y
  decide
