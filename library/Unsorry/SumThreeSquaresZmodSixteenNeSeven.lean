import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-three-squares-zmod-sixteen-ne-seven`: over `ℤ`, `a ^ 2 + b ^ 2 + c ^ 2` is never `7` in `ZMod 16`,
by reducing the integer cast to `ZMod 16` and a finite case check. -/
theorem sum_three_squares_zmod_sixteen_ne_seven (a b c : ℤ) : (((a ^ 2 + b ^ 2 + c ^ 2 : ℤ)) : ZMod 16) ≠ 7 := by
  have h : (((a ^ 2 + b ^ 2 + c ^ 2 : ℤ)) : ZMod 16) = (a : ZMod 16) ^ 2 + (b : ZMod 16) ^ 2 + (c : ZMod 16) ^ 2 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 16) = x
  generalize (b : ZMod 16) = y
  generalize (c : ZMod 16) = z
  revert x y z
  decide
