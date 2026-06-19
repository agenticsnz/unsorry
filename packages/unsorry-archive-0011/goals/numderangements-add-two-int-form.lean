import Mathlib

theorem numderangements_add_two_int_form (n : ℕ) :
    (numDerangements (n + 2) : ℤ) =
      (n + 1) * ((numDerangements (n + 1) : ℤ) + (numDerangements n : ℤ)) := by
  sorry
