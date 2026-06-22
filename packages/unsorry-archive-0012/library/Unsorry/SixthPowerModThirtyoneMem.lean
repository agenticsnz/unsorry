import Mathlib

theorem sixth_power_mod_thirtyone_mem (n : ℕ) : n ^ 6 % 31 = 0 ∨ n ^ 6 % 31 = 1 ∨ n ^ 6 % 31 = 2 ∨ n ^ 6 % 31 = 4 ∨ n ^ 6 % 31 = 8 ∨ n ^ 6 % 31 = 16 := by
  rw [Nat.pow_mod]
  have h : n % 31 < 31 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 31) <;> decide
