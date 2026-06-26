import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_three_squares_zmod_eight_ne_seven (a b c : ℤ) : (((a ^ 2 + b ^ 2 + c ^ 2 : ℤ)) : ZMod 8) ≠ 7 := by
  first
    | (push_cast; generalize (a : ZMod 8) = z0; generalize (b : ZMod 8) = z1; generalize (c : ZMod 8) = z2; revert z0 z1 z2; decide)
    | (generalize (a : ZMod 8) = z0; generalize (b : ZMod 8) = z1; generalize (c : ZMod 8) = z2; revert z0 z1 z2; decide)
    | (push_cast; decide)
    | decide
