import Mathlib

theorem sq_mod_twelve_mem (n : ℕ) : n ^ 2 % 12 = 0 ∨ n ^ 2 % 12 = 1 ∨ n ^ 2 % 12 = 4 ∨ n ^ 2 % 12 = 9 := by
  rw [Nat.pow_mod]
  have h : n % 12 < 12 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 12) <;> decide
