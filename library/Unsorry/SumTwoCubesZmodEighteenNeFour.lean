import Mathlib

set_option maxRecDepth 8000 in
/-- Goal `sum-two-cubes-zmod-eighteen-ne-four`: over `ℤ`, `a ^ 3 + b ^ 3` is never `4` in `ZMod 18`,
by reducing the integer cast to `ZMod 18` and a finite case check. -/
theorem sum_two_cubes_zmod_eighteen_ne_four (a b : ℤ) : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 18) ≠ 4 := by
  have h : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 18) = (a : ZMod 18) ^ 3 + (b : ZMod 18) ^ 3 := by push_cast; ring
  rw [h]
  generalize (a : ZMod 18) = x
  generalize (b : ZMod 18) = y
  revert x y
  decide
