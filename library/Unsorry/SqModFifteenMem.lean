import Mathlib.Tactic.IntervalCases

theorem sq_mod_fifteen_mem (n : ℕ) : n ^ 2 % 15 = 0 ∨ n ^ 2 % 15 = 1 ∨ n ^ 2 % 15 = 4 ∨ n ^ 2 % 15 = 6 ∨ n ^ 2 % 15 = 9 ∨ n ^ 2 % 15 = 10 := by
  have h : n ^ 2 % 15 = (n % 15) ^ 2 % 15 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 15 < 15 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 15) <;> decide
