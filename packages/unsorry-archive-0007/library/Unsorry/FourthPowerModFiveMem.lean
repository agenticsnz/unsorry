import Mathlib.Tactic.IntervalCases

theorem fourth_power_mod_five_mem (n : ℕ) : n ^ 4 % 5 = 0 ∨ n ^ 4 % 5 = 1 := by
  have h : n ^ 4 % 5 = (n % 5) ^ 4 % 5 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 5 < 5 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 5) <;> decide
