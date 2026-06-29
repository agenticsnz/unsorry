import Mathlib

theorem sq_mod_thirtytwo_mem (n : ℕ) : n ^ 2 % 32 = 0 ∨ n ^ 2 % 32 = 1 ∨ n ^ 2 % 32 = 4 ∨ n ^ 2 % 32 = 9 ∨ n ^ 2 % 32 = 16 ∨ n ^ 2 % 32 = 17 ∨ n ^ 2 % 32 = 25 := by
  rw [Nat.pow_mod]
  have h : n % 32 < 32 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 32) <;> decide
