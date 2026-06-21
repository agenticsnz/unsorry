import Mathlib.Tactic.IntervalCases

theorem fourth_power_mod_ten_mem (n : ℕ) : n ^ 4 % 10 = 0 ∨ n ^ 4 % 10 = 1 ∨ n ^ 4 % 10 = 5 ∨ n ^ 4 % 10 = 6 := by
  have h : n ^ 4 % 10 = (n % 10) ^ 4 % 10 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 10 < 10 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 10) <;> decide
