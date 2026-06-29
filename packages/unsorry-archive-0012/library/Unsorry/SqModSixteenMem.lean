import Mathlib

theorem sq_mod_sixteen_mem (n : ℕ) : n ^ 2 % 16 = 0 ∨ n ^ 2 % 16 = 1 ∨ n ^ 2 % 16 = 4 ∨ n ^ 2 % 16 = 9 := by
  rw [Nat.pow_mod]
  have h : n % 16 < 16 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 16) <;> decide
