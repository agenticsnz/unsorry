import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-cubes-zmod-twentyone-ne-eleven`: over `ℤ`, `a ^ 3 + b ^ 3` is never `11` in `ZMod 21`,
by reducing the integer cast to `ZMod 21` and a finite case check. -/
theorem sum_two_cubes_zmod_twentyone_ne_eleven (a b : ℤ) : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 21) ≠ 11 := by
  have h : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 21) = (a : ZMod 21) ^ 3 + (b : ZMod 21) ^ 3 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 21) = x
  generalize (b : ZMod 21) = y
  revert x y
  decide
