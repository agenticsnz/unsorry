import Mathlib

theorem fifth_power_mod_sixteen_odd_mem (n : ℕ) : n ^ 5 % 16 = 0 ∨ n ^ 5 % 16 = 1 ∨ n ^ 5 % 16 = 3 ∨ n ^ 5 % 16 = 5 ∨ n ^ 5 % 16 = 7 ∨ n ^ 5 % 16 = 9 ∨ n ^ 5 % 16 = 11 ∨ n ^ 5 % 16 = 13 ∨ n ^ 5 % 16 = 15 := by
  have key : n ^ 5 % 16 = (n % 16) ^ 5 % 16 := ((Nat.mod_modEq n 16).pow 5).symm
  rw [key]
  have hlt : n % 16 < 16 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 16) <;> decide
