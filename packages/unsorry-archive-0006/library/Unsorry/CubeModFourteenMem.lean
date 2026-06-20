import Mathlib

theorem cube_mod_fourteen_mem (n : ℕ) : n ^ 3 % 14 = 0 ∨ n ^ 3 % 14 = 1 ∨ n ^ 3 % 14 = 6 ∨ n ^ 3 % 14 = 7 ∨ n ^ 3 % 14 = 8 ∨ n ^ 3 % 14 = 13 := by
  have key : n ^ 3 % 14 = (n % 14) ^ 3 % 14 := ((Nat.mod_modEq n 14).pow 3).symm
  rw [key]
  have hlt : n % 14 < 14 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 14) <;> decide
