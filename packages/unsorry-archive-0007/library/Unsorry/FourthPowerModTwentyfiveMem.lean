import Mathlib

theorem fourth_power_mod_twentyfive_mem (n : ℕ) : n ^ 4 % 25 = 0 ∨ n ^ 4 % 25 = 1 ∨ n ^ 4 % 25 = 6 ∨ n ^ 4 % 25 = 11 ∨ n ^ 4 % 25 = 16 ∨ n ^ 4 % 25 = 21 := by
  have key : n ^ 4 % 25 = (n % 25) ^ 4 % 25 := ((Nat.mod_modEq n 25).pow 4).symm
  rw [key]
  have hlt : n % 25 < 25 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 25) <;> decide
