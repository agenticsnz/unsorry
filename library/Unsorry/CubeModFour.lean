import Mathlib.Tactic.IntervalCases

theorem cube_mod_four (n : ℕ) : n ^ 3 % 4 = 0 ∨ n ^ 3 % 4 = 1 ∨ n ^ 3 % 4 = 3 := by
  have h : n ^ 3 % 4 = (n % 4) ^ 3 % 4 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 4 < 4 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 4) <;> decide
