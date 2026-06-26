import Mathlib.Tactic.IntervalCases

theorem cube_mod_twentyseven_mem (n : ℕ) : n ^ 3 % 27 = 0 ∨ n ^ 3 % 27 = 1 ∨ n ^ 3 % 27 = 8 ∨ n ^ 3 % 27 = 10 ∨ n ^ 3 % 27 = 17 ∨ n ^ 3 % 27 = 19 ∨ n ^ 3 % 27 = 26 := by
  have h : n ^ 3 % 27 = (n % 27) ^ 3 % 27 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 27 < 27 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 27) <;> decide