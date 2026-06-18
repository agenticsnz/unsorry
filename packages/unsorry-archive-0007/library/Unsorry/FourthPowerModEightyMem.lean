import Mathlib

set_option maxRecDepth 8000 in
theorem fourth_power_mod_eighty_mem (n : ℕ) : n ^ 4 % 80 = 0 ∨ n ^ 4 % 80 = 1 ∨ n ^ 4 % 80 = 16 ∨ n ^ 4 % 80 = 65 := by
  have key : n ^ 4 % 80 = (n % 80) ^ 4 % 80 := ((Nat.mod_modEq n 80).pow 4).symm
  rw [key]
  have hlt : n % 80 < 80 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 80) <;> decide
