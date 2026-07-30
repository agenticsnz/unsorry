import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-twenty-ne-fifteen`: over `ℤ`, `a ^ 2 + b ^ 2` is never `15` in `ZMod 20`,
by reducing the integer cast to `ZMod 20` and a finite case check. -/
theorem sum_two_squares_zmod_twenty_ne_fifteen (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 20) ≠ 15 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 20) = (a : ZMod 20) ^ 2 + (b : ZMod 20) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 20) = x
  generalize (b : ZMod 20) = y
  revert x y
  decide
