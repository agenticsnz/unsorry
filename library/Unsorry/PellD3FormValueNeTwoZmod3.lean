import Mathlib

theorem pell_d3_form_value_ne_two_zmod3 (x y : ℤ) :
    ¬ (x^2 - 3 * y^2 = 2) := by
  intro heq
  have key : ∀ a b : ZMod 3, a ^ 2 - 3 * b ^ 2 ≠ 2 := by decide
  apply key (x : ZMod 3) (y : ZMod 3)
  have hcast := congrArg (fun t : ℤ => (t : ZMod 3)) heq
  push_cast at hcast
  exact hcast
