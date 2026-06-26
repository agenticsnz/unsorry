import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_three_squares_zmod_sixteen_ne_fifteen (a b c : ℤ) : (((a ^ 2 + b ^ 2 + c ^ 2 : ℤ)) : ZMod 16) ≠ 15 := by
  first
    | (push_cast; generalize (a : ZMod 16) = z0; generalize (b : ZMod 16) = z1; generalize (c : ZMod 16) = z2; revert z0 z1 z2; decide)
    | (generalize (a : ZMod 16) = z0; generalize (b : ZMod 16) = z1; generalize (c : ZMod 16) = z2; revert z0 z1 z2; decide)
    | (push_cast; decide)
    | decide
