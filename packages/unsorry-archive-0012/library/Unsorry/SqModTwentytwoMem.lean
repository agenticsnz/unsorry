import Mathlib

theorem sq_mod_twentytwo_mem (n : ℕ) : n ^ 2 % 22 = 0 ∨ n ^ 2 % 22 = 1 ∨ n ^ 2 % 22 = 3 ∨ n ^ 2 % 22 = 4 ∨ n ^ 2 % 22 = 5 ∨ n ^ 2 % 22 = 9 ∨ n ^ 2 % 22 = 11 ∨ n ^ 2 % 22 = 12 ∨ n ^ 2 % 22 = 14 ∨ n ^ 2 % 22 = 15 ∨ n ^ 2 % 22 = 16 ∨ n ^ 2 % 22 = 20 := by
  rw [Nat.pow_mod]
  have h : n % 22 < 22 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 22) <;> decide
