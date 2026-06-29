import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_two_squares_zmod_eight_ne_six (m n : ℤ) : (((m ^ 2 + n ^ 2 : ℤ)) : ZMod 8) ≠ 6 := by
  first
    | (push_cast; generalize (m : ZMod 8) = z0; generalize (n : ZMod 8) = z1; revert z0 z1; decide)
    | (generalize (m : ZMod 8) = z0; generalize (n : ZMod 8) = z1; revert z0 z1; decide)
    | (push_cast; decide)
    | decide
