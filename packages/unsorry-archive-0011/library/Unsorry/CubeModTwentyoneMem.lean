import Mathlib.Tactic.IntervalCases

theorem cube_mod_twentyone_mem (n : ℕ) : n ^ 3 % 21 = 0 ∨ n ^ 3 % 21 = 1 ∨ n ^ 3 % 21 = 6 ∨ n ^ 3 % 21 = 7 ∨ n ^ 3 % 21 = 8 ∨ n ^ 3 % 21 = 13 ∨ n ^ 3 % 21 = 14 ∨ n ^ 3 % 21 = 15 ∨ n ^ 3 % 21 = 20 := by
  have h : n ^ 3 % 21 = (n % 21) ^ 3 % 21 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 21 < 21 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 21) <;> decide