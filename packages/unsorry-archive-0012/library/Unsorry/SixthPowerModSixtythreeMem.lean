import Mathlib

theorem sixth_power_mod_sixtythree_mem (n : ℕ) : n ^ 6 % 63 = 0 ∨ n ^ 6 % 63 = 1 ∨ n ^ 6 % 63 = 28 ∨ n ^ 6 % 63 = 36 := by
  rw [Nat.pow_mod]
  have h : n % 63 < 63 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 63) <;> decide
