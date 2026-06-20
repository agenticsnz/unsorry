import Mathlib

set_option maxRecDepth 8000 in
theorem fourth_power_mod_hundred_mem (n : ℕ) :
    n ^ 4 % 100 ∈ ({0, 1, 16, 21, 25, 36, 41, 56, 61, 76, 81, 96} : Finset ℕ) := by
  have key : n ^ 4 % 100 = (n % 100) ^ 4 % 100 := ((Nat.mod_modEq n 100).pow 4).symm
  rw [key]
  have hlt : n % 100 < 100 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 100) <;> decide
