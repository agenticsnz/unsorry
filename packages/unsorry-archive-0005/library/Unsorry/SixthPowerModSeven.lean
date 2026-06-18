import Mathlib.Tactic.IntervalCases

theorem sixth_power_mod_seven (n : ℕ) : n ^ 6 % 7 = 0 ∨ n ^ 6 % 7 = 1 := by
  have h : n ^ 6 % 7 = (n % 7) ^ 6 % 7 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 7 < 7 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 7) <;> decide
