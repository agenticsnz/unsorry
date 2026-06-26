import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-squares-zmod-twelve-ne-seven`: over `ℤ`, `a^2 + b^2` is never `7` in `ZMod 12`,
by reducing the integer cast to `ZMod 12` and a finite case check. -/
theorem sum_two_squares_zmod_twelve_ne_seven (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 12) ≠ 7 := by
  have h : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 12)
      = (a : ZMod 12) ^ 2 + (b : ZMod 12) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 12) = x
  generalize (b : ZMod 12) = y
  revert x y
  decide
