import Mathlib

theorem sq_mod_ten_ne_two_three_seven_eight (n : ℕ) : n ^ 2 % 10 ≠ 2 ∧ n ^ 2 % 10 ≠ 3 ∧ n ^ 2 % 10 ≠ 7 ∧ n ^ 2 % 10 ≠ 8 := by
  have h : n ^ 2 % 10 = (n % 10) ^ 2 % 10 := by rw [Nat.pow_mod]
  rw [h]
  have : n % 10 < 10 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 10) <;> decide