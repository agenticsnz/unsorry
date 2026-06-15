import Mathlib.Tactic.IntervalCases

theorem fourth_power_mod_sixteen_mem (n : ℕ) : n ^ 4 % 16 = 0 ∨ n ^ 4 % 16 = 1 := by
  have h : n ^ 4 % 16 = (n % 16) ^ 4 % 16 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 16 < 16 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 16) <;> decide
