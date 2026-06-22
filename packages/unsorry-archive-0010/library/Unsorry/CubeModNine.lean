import Mathlib.Tactic.IntervalCases

/-- The cube of any natural number is congruent to `0`, `1`, or `8` modulo `9`. -/
theorem cube_mod_nine (n : ℕ) : n ^ 3 % 9 = 0 ∨ n ^ 3 % 9 = 1 ∨ n ^ 3 % 9 = 8 := by
  have h : n ^ 3 % 9 = (n % 9) ^ 3 % 9 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 9 < 9 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 9) <;> decide
