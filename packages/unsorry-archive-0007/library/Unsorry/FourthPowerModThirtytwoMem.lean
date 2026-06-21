import Mathlib

theorem fourth_power_mod_thirtytwo_mem (n : ℕ) : n ^ 4 % 32 = 0 ∨ n ^ 4 % 32 = 1 ∨ n ^ 4 % 32 = 16 ∨ n ^ 4 % 32 = 17 := by
  have key : n ^ 4 % 32 = (n % 32) ^ 4 % 32 := ((Nat.mod_modEq n 32).pow 4).symm
  rw [key]
  have hlt : n % 32 < 32 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 32) <;> decide
