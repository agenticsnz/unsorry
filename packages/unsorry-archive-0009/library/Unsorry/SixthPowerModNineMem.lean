import Mathlib.Tactic.IntervalCases

theorem sixth_power_mod_nine_mem (n : ℕ) : n ^ 6 % 9 = 0 ∨ n ^ 6 % 9 = 1 := by
  have h : n ^ 6 % 9 = (n % 9) ^ 6 % 9 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 9 < 9 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 9) <;> decide
