import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_two_cubes_zmod_seven_mem (a b : ℤ) : (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 7) ≠ 3 ∧ (((a ^ 3 + b ^ 3 : ℤ)) : ZMod 7) ≠ 4 := by
  first
    | (push_cast; generalize (a : ZMod 7) = z0; generalize (b : ZMod 7) = z1; revert z0 z1; decide)
    | (generalize (a : ZMod 7) = z0; generalize (b : ZMod 7) = z1; revert z0 z1; decide)
    | (push_cast; decide)
    | decide
