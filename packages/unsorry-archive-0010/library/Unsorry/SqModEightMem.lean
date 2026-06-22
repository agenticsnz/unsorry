import Mathlib.Tactic.IntervalCases

theorem sq_mod_eight_mem (n : ℕ) : n ^ 2 % 8 = 0 ∨ n ^ 2 % 8 = 1 ∨ n ^ 2 % 8 = 4 := by
  have h : n ^ 2 % 8 = (n % 8) ^ 2 % 8 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 8 < 8 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 8) <;> decide
