import Mathlib

theorem cube_mod_twentysix_mem (n : ℕ) : n ^ 3 % 26 = 0 ∨ n ^ 3 % 26 = 1 ∨ n ^ 3 % 26 = 5 ∨ n ^ 3 % 26 = 8 ∨ n ^ 3 % 26 = 12 ∨ n ^ 3 % 26 = 13 ∨ n ^ 3 % 26 = 14 ∨ n ^ 3 % 26 = 18 ∨ n ^ 3 % 26 = 21 ∨ n ^ 3 % 26 = 25 := by
  have key : n ^ 3 % 26 = (n % 26) ^ 3 % 26 := ((Nat.mod_modEq n 26).pow 3).symm
  rw [key]
  have hlt : n % 26 < 26 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 26) <;> decide
