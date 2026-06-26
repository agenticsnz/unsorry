import Mathlib

theorem sq_mod_twenty_mem (n : ℕ) : n ^ 2 % 20 = 0 ∨ n ^ 2 % 20 = 1 ∨ n ^ 2 % 20 = 4 ∨ n ^ 2 % 20 = 5 ∨ n ^ 2 % 20 = 9 ∨ n ^ 2 % 20 = 16 := by
  rw [Nat.pow_mod]
  have h : n % 20 < 20 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 20) <;> decide
