import Mathlib

theorem sq_mod_twentyfive_mem (n : ℕ) : n ^ 2 % 25 = 0 ∨ n ^ 2 % 25 = 1 ∨ n ^ 2 % 25 = 4 ∨ n ^ 2 % 25 = 6 ∨ n ^ 2 % 25 = 9 ∨ n ^ 2 % 25 = 11 ∨ n ^ 2 % 25 = 14 ∨ n ^ 2 % 25 = 16 ∨ n ^ 2 % 25 = 19 ∨ n ^ 2 % 25 = 21 ∨ n ^ 2 % 25 = 24 := by
  rw [Nat.pow_mod]
  have h : n % 25 < 25 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 25) <;> decide
