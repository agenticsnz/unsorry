import Mathlib.Tactic.IntervalCases

set_option maxRecDepth 8000 in
theorem cube_mod_eighteen_mem (n : ℕ) : n ^ 3 % 18 = 0 ∨ n ^ 3 % 18 = 1 ∨ n ^ 3 % 18 = 8 ∨ n ^ 3 % 18 = 9 ∨ n ^ 3 % 18 = 10 ∨ n ^ 3 % 18 = 17 := by
  have h : n ^ 3 % 18 = (n % 18) ^ 3 % 18 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 18 < 18 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 18) <;> decide
