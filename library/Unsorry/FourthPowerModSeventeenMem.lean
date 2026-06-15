import Mathlib.Tactic.IntervalCases

set_option maxRecDepth 8000 in
theorem fourth_power_mod_seventeen_mem (n : ℕ) : n ^ 4 % 17 = 0 ∨ n ^ 4 % 17 = 1 ∨ n ^ 4 % 17 = 4 ∨ n ^ 4 % 17 = 13 ∨ n ^ 4 % 17 = 16 := by
  have h : n ^ 4 % 17 = (n % 17) ^ 4 % 17 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 17 < 17 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 17) <;> decide
