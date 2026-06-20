import Mathlib.Tactic.IntervalCases

theorem sq_mod_seven (n : ℕ) :
    n ^ 2 % 7 = 0 ∨ n ^ 2 % 7 = 1 ∨ n ^ 2 % 7 = 2 ∨ n ^ 2 % 7 = 4 := by
  have h : n ^ 2 % 7 = (n % 7) ^ 2 % 7 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 7 < 7 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 7) <;> decide
