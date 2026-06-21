import Mathlib

set_option maxRecDepth 8000 in
theorem eleventh_power_mod_twentythree_mem (n : ℕ) : n ^ 11 % 23 = 0 ∨ n ^ 11 % 23 = 1 ∨ n ^ 11 % 23 = 22 := by
  have key : n ^ 11 % 23 = (n % 23) ^ 11 % 23 := ((Nat.mod_modEq n 23).pow 11).symm
  rw [key]
  have hlt : n % 23 < 23 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 23) <;> decide
