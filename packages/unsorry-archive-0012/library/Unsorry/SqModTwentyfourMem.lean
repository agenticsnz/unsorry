import Mathlib

theorem sq_mod_twentyfour_mem (n : ℕ) : n ^ 2 % 24 = 0 ∨ n ^ 2 % 24 = 1 ∨ n ^ 2 % 24 = 4 ∨ n ^ 2 % 24 = 9 ∨ n ^ 2 % 24 = 12 ∨ n ^ 2 % 24 = 16 := by
  rw [Nat.pow_mod]
  have h : n % 24 < 24 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 24) <;> decide
