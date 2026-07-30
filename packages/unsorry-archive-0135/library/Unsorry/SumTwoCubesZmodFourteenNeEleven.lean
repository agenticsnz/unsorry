import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-cubes-zmod-fourteen-ne-eleven`: over `ℤ`, `a ^ 3 + b ^ 3` is never `11` in `ZMod 14`,
by reducing the integer cast to `ZMod 14` and a finite case check. -/
theorem sum_two_cubes_zmod_fourteen_ne_eleven (a b : ℤ) : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 14) ≠ 11 := by
  have h : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 14) = (a : ZMod 14) ^ 3 + (b : ZMod 14) ^ 3 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 14) = x
  generalize (b : ZMod 14) = y
  revert x y
  decide
