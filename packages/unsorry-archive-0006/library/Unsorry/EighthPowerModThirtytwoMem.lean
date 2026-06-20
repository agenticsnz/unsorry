import Mathlib

set_option maxRecDepth 8000 in
theorem eighth_power_mod_thirtytwo_mem (n : ℕ) : n ^ 8 % 32 = 0 ∨ n ^ 8 % 32 = 1 := by
  have key : n ^ 8 % 32 = (n % 32) ^ 8 % 32 := ((Nat.mod_modEq n 32).pow 8).symm
  rw [key]
  have hlt : n % 32 < 32 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 32) <;> decide
