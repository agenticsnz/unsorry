import Mathlib.Combinatorics.Derangements.Finite

theorem numderangements_add_two_int_form (n : ℕ) :
    (numDerangements (n + 2) : ℤ) =
      (n + 1) * ((numDerangements (n + 1) : ℤ) + (numDerangements n : ℤ)) := by
  rw [numDerangements_add_two]
  simp [add_comm]
