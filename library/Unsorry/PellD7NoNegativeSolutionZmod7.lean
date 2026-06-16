import Mathlib

theorem pell_d7_no_negative_solution_zmod7 : ¬ ∃ x y : ℤ, x ^ 2 - 7 * y ^ 2 = -1 := by
  rintro ⟨x, y, heq⟩
  have key : ∀ a b : ZMod 7, a ^ 2 - 7 * b ^ 2 ≠ -1 := by decide
  apply key (x : ZMod 7) (y : ZMod 7)
  have hcast := congrArg (fun t : ℤ => (t : ZMod 7)) heq
  push_cast at hcast
  exact hcast
