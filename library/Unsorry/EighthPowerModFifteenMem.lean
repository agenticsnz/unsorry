import Mathlib.Tactic.IntervalCases

theorem eighth_power_mod_fifteen_mem (n : ℕ) : n ^ 8 % 15 = 0 ∨ n ^ 8 % 15 = 1 ∨ n ^ 8 % 15 = 6 ∨ n ^ 8 % 15 = 10 := by
  have h : n ^ 8 % 15 = (n % 15) ^ 8 % 15 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 15 < 15 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 15) <;> decide
