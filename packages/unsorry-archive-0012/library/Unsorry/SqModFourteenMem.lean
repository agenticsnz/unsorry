import Mathlib

theorem sq_mod_fourteen_mem (n : ℕ) : n ^ 2 % 14 = 0 ∨ n ^ 2 % 14 = 1 ∨ n ^ 2 % 14 = 2 ∨ n ^ 2 % 14 = 4 ∨ n ^ 2 % 14 = 7 ∨ n ^ 2 % 14 = 8 ∨ n ^ 2 % 14 = 9 ∨ n ^ 2 % 14 = 11 := by
  rw [Nat.pow_mod]
  have h : n % 14 < 14 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 14) <;> decide
