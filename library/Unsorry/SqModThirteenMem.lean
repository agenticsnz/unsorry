import Mathlib.Tactic.IntervalCases

theorem sq_mod_thirteen_mem (n : ℕ) : n ^ 2 % 13 = 0 ∨ n ^ 2 % 13 = 1 ∨ n ^ 2 % 13 = 3 ∨ n ^ 2 % 13 = 4 ∨ n ^ 2 % 13 = 9 ∨ n ^ 2 % 13 = 10 ∨ n ^ 2 % 13 = 12 := by
  have h : n ^ 2 % 13 = (n % 13) ^ 2 % 13 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 13 < 13 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 13) <;> decide
