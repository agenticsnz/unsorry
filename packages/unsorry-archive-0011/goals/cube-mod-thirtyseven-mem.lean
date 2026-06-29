import Mathlib

set_option maxRecDepth 8000 in
theorem cube_mod_thirtyseven_mem (n : ℕ) : n ^ 3 % 37 ∈ ({0, 1, 6, 8, 10, 11, 14, 23, 26, 27, 29, 31, 36} : Finset ℕ) := by
  sorry
