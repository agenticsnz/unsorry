import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-cubes-zmod-nine-ne-five`: over `ℤ`, `a ^ 3 + b ^ 3` is never `5` in `ZMod 9`,
by reducing the integer cast to `ZMod 9` and a finite case check. -/
theorem sum_two_cubes_zmod_nine_ne_five (a b : ℤ) : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 9) ≠ 5 := by
  have h : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 9) = (a : ZMod 9) ^ 3 + (b : ZMod 9) ^ 3 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 9) = x
  generalize (b : ZMod 9) = y
  revert x y
  decide
