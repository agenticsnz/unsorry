import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-eight-ne-three`: over `ℤ`, `a ^ 2 + b ^ 2` is never `3` in `ZMod 8`,
by reducing the integer cast to `ZMod 8` and a finite case check. -/
theorem sum_two_squares_zmod_eight_ne_three (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 8) ≠ 3 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 8) = (a : ZMod 8) ^ 2 + (b : ZMod 8) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 8) = x
  generalize (b : ZMod 8) = y
  revert x y
  decide
