import Mathlib

theorem sixth_power_mod_twentyone_mem (n : ℕ) : n ^ 6 % 21 = 0 ∨ n ^ 6 % 21 = 1 ∨ n ^ 6 % 21 = 7 ∨ n ^ 6 % 21 = 15 := by
  rw [Nat.pow_mod]
  have h : n % 21 < 21 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 21) <;> decide
