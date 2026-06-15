import Mathlib.Tactic.IntervalCases

theorem cube_mod_seven (n : ℕ) : n ^ 3 % 7 = 0 ∨ n ^ 3 % 7 = 1 ∨ n ^ 3 % 7 = 6 := by
  have h : n ^ 3 % 7 = (n % 7) ^ 3 % 7 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 7 < 7 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 7) <;> decide
