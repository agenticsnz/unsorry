import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-cubes-zmod-seven-ne-four`: over `ℤ`, `a ^ 3 + b ^ 3` is never `4` in `ZMod 7`,
by reducing the integer cast to `ZMod 7` and a finite case check. -/
theorem sum_two_cubes_zmod_seven_ne_four (a b : ℤ) : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 7) ≠ 4 := by
  have h : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 7) = (a : ZMod 7) ^ 3 + (b : ZMod 7) ^ 3 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 7) = x
  generalize (b : ZMod 7) = y
  revert x y
  decide
