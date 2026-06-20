import Mathlib

theorem sq_mod_five (n : ℕ) : n ^ 2 % 5 = 0 ∨ n ^ 2 % 5 = 1 ∨ n ^ 2 % 5 = 4 := by
  rw [Nat.pow_mod]
  have h : n % 5 < 5 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 5) <;> decide
