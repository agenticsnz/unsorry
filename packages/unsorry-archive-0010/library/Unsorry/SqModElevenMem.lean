import Mathlib.Tactic.IntervalCases

theorem sq_mod_eleven_mem (n : ℕ) : n ^ 2 % 11 = 0 ∨ n ^ 2 % 11 = 1 ∨ n ^ 2 % 11 = 3 ∨ n ^ 2 % 11 = 4 ∨ n ^ 2 % 11 = 5 ∨ n ^ 2 % 11 = 9 := by
  have h : n ^ 2 % 11 = (n % 11) ^ 2 % 11 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 11 < 11 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 11) <;> decide
