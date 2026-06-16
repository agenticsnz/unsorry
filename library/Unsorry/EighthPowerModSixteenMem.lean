import Mathlib

set_option maxRecDepth 8000 in
theorem eighth_power_mod_sixteen_mem (n : ℕ) : n ^ 8 % 16 = 0 ∨ n ^ 8 % 16 = 1 := by
  have key : n ^ 8 % 16 = (n % 16) ^ 8 % 16 := ((Nat.mod_modEq n 16).pow 8).symm
  rw [key]
  have hlt : n % 16 < 16 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 16) <;> decide
