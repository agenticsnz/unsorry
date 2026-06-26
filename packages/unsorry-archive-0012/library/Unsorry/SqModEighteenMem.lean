import Mathlib

theorem sq_mod_eighteen_mem (n : ℕ) : n ^ 2 % 18 = 0 ∨ n ^ 2 % 18 = 1 ∨ n ^ 2 % 18 = 4 ∨ n ^ 2 % 18 = 7 ∨ n ^ 2 % 18 = 9 ∨ n ^ 2 % 18 = 10 ∨ n ^ 2 % 18 = 13 ∨ n ^ 2 % 18 = 16 := by
  rw [Nat.pow_mod]
  have h : n % 18 < 18 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 18) <;> decide
