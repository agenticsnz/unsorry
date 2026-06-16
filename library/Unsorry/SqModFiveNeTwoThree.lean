import Mathlib

theorem sq_mod_five_ne_two_three (n : ℕ) : n ^ 2 % 5 ≠ 2 ∧ n ^ 2 % 5 ≠ 3 := by
  have h : n ^ 2 % 5 = (n % 5) ^ 2 % 5 := by
    rw [Nat.pow_mod]
  rw [h]
  have : n % 5 < 5 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 5) <;> decide