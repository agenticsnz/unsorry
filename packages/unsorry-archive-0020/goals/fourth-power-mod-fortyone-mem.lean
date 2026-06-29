import Mathlib

theorem fourth_power_mod_fortyone_mem (r : ℕ) (hr : r < 41) : (∃ n : ℕ, n ^ 4 % 41 = r) ↔ r ∈ ({0, 1, 4, 10, 16, 18, 23, 25, 31, 37, 40} : Finset ℕ) := by
  sorry
