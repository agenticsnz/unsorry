import Mathlib

set_option maxRecDepth 8000 in
theorem cube_mod_nineteen_mem (n : ℕ) : n ^ 3 % 19 = 0 ∨ n ^ 3 % 19 = 1 ∨ n ^ 3 % 19 = 7 ∨ n ^ 3 % 19 = 8 ∨ n ^ 3 % 19 = 11 ∨ n ^ 3 % 19 = 12 ∨ n ^ 3 % 19 = 18 := by
  have key : n ^ 3 % 19 = (n % 19) ^ 3 % 19 := ((Nat.mod_modEq n 19).pow 3).symm
  rw [key]
  have hlt : n % 19 < 19 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 19) <;> decide
