import Mathlib

set_option maxRecDepth 8000 in
set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem three_fourth_powers_zmod_sixteen_mem (a b c : ℤ) :
    ((a^4 + b^4 + c^4 : ℤ) : ZMod 16) ∈ ({0, 1, 2, 3} : Set (ZMod 16)) := by
  first
    | (push_cast; generalize (a : ZMod 16) = z0; generalize (b : ZMod 16) = z1; generalize (c : ZMod 16) = z2; revert z0 z1 z2; decide)
    | (generalize (a : ZMod 16) = z0; generalize (b : ZMod 16) = z1; generalize (c : ZMod 16) = z2; revert z0 z1 z2; decide)
    | (push_cast; decide)
    | decide
