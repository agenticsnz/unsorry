import Mathlib

theorem eighth_power_mod_seventeen_mem (n : ℕ) : n ^ 8 % 17 = 0 ∨ n ^ 8 % 17 = 1 ∨ n ^ 8 % 17 = 16 := by
  have key : n ^ 8 % 17 = (n % 17) ^ 8 % 17 := ((Nat.mod_modEq n 17).pow 8).symm
  rw [key]
  have hlt : n % 17 < 17 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 17) <;> decide
