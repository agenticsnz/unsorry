import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-sixteen-ne-fourteen`: over `ℤ`, `a ^ 2 + b ^ 2` is never `14` in `ZMod 16`,
by reducing the integer cast to `ZMod 16` and a finite case check. -/
theorem sum_two_squares_zmod_sixteen_ne_fourteen (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 16) ≠ 14 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 16) = (a : ZMod 16) ^ 2 + (b : ZMod 16) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 16) = x
  generalize (b : ZMod 16) = y
  revert x y
  decide
