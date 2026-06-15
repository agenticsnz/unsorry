import Mathlib.Tactic.IntervalCases

theorem fourth_power_mod_thirteen_mem (n : ℕ) : n ^ 4 % 13 = 0 ∨ n ^ 4 % 13 = 1 ∨ n ^ 4 % 13 = 3 ∨ n ^ 4 % 13 = 9 := by
  have h : n ^ 4 % 13 = (n % 13) ^ 4 % 13 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 13 < 13 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 13) <;> decide
