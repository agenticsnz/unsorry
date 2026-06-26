import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-eighteen-ne-fifteen`: over `ℤ`, `a ^ 2 + b ^ 2` is never `15` in `ZMod 18`,
by reducing the integer cast to `ZMod 18` and a finite case check. -/
theorem sum_two_squares_zmod_eighteen_ne_fifteen (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 18) ≠ 15 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 18) = (a : ZMod 18) ^ 2 + (b : ZMod 18) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 18) = x
  generalize (b : ZMod 18) = y
  revert x y
  decide
