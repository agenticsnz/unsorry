import Mathlib

theorem sq_mod_nine (n : ℕ) :
    n ^ 2 % 9 = 0 ∨ n ^ 2 % 9 = 1 ∨ n ^ 2 % 9 = 4 ∨ n ^ 2 % 9 = 7 := by
  rw [Nat.pow_mod]
  have h : n % 9 < 9 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 9) <;> decide
