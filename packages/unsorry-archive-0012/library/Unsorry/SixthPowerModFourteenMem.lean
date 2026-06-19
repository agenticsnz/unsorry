import Mathlib

theorem sixth_power_mod_fourteen_mem (n : ℕ) : n ^ 6 % 14 = 0 ∨ n ^ 6 % 14 = 1 ∨ n ^ 6 % 14 = 7 ∨ n ^ 6 % 14 = 8 := by
  rw [Nat.pow_mod]
  have h : n % 14 < 14 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 14) <;> decide
