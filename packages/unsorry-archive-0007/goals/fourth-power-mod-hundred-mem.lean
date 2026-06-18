import Mathlib

set_option maxRecDepth 8000 in
theorem fourth_power_mod_hundred_mem (n : ℕ) :
    n ^ 4 % 100 ∈ ({0, 1, 16, 21, 25, 36, 41, 56, 61, 76, 81, 96} : Finset ℕ) := by
  sorry
