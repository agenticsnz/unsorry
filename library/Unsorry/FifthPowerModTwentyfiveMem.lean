import Mathlib.Tactic.IntervalCases

set_option maxRecDepth 8000 in
theorem fifth_power_mod_twentyfive_mem (n : ℕ) : n ^ 5 % 25 = 0 ∨ n ^ 5 % 25 = 1 ∨ n ^ 5 % 25 = 7 ∨ n ^ 5 % 25 = 18 ∨ n ^ 5 % 25 = 24 := by
  have h : n ^ 5 % 25 = (n % 25) ^ 5 % 25 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 25 < 25 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 25) <;> decide
