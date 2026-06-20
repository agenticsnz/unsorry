import Mathlib

set_option maxRecDepth 8000 in
theorem fourth_power_mod_fortyeight_mem (n : ℕ) :
    n^4 % 48 = 0 ∨ n^4 % 48 = 1 ∨ n^4 % 48 = 16 ∨ n^4 % 48 = 33 := by
  have key : n ^ 4 % 48 = (n % 48) ^ 4 % 48 := ((Nat.mod_modEq n 48).pow 4).symm
  rw [key]
  have hlt : n % 48 < 48 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 48) <;> decide
