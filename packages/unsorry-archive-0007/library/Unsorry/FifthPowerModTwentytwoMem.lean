import Mathlib

theorem fifth_power_mod_twentytwo_mem (n : ℕ) : n ^ 5 % 22 = 0 ∨ n ^ 5 % 22 = 1 ∨ n ^ 5 % 22 = 10 ∨ n ^ 5 % 22 = 11 ∨ n ^ 5 % 22 = 12 ∨ n ^ 5 % 22 = 21 := by
  have key : n ^ 5 % 22 = (n % 22) ^ 5 % 22 := ((Nat.mod_modEq n 22).pow 5).symm
  rw [key]
  have hlt : n % 22 < 22 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 22) <;> decide
