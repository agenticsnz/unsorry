import Mathlib

theorem sq_mod_ten_mem (n : ℕ) : n ^ 2 % 10 = 0 ∨ n ^ 2 % 10 = 1 ∨ n ^ 2 % 10 = 4 ∨ n ^ 2 % 10 = 5 ∨ n ^ 2 % 10 = 6 ∨ n ^ 2 % 10 = 9 := by
  rw [Nat.pow_mod]
  have h : n % 10 < 10 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 10) <;> decide
