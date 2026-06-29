import Mathlib.Tactic.IntervalCases

theorem sixth_power_mod_thirteen_mem (n : ℕ) : n ^ 6 % 13 = 0 ∨ n ^ 6 % 13 = 1 ∨ n ^ 6 % 13 = 12 := by
  have h : n ^ 6 % 13 = (n % 13) ^ 6 % 13 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 13 < 13 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 13) <;> decide
