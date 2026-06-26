import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring

/-- Goal `sum-two-squares-zmod-four-ne-three`: a sum of two integer squares is never `≡ 3 (mod 4)`,
since every square is `0` or `1` mod `4`. Finite `decide` over `ZMod 4`. -/
theorem sum_two_squares_zmod_four_ne_three (a b : ℤ) : (((a ^ 2 + b ^ 2 : ℤ)) : ZMod 4) ≠ 3 := by
  have key : ∀ x y : ZMod 4, x ^ 2 + y ^ 2 ≠ 3 := by decide
  have hcast : ((a ^ 2 + b ^ 2 : ℤ) : ZMod 4) = (a : ZMod 4) ^ 2 + (b : ZMod 4) ^ 2 := by
    push_cast; ring
  rw [hcast]; exact key _ _
