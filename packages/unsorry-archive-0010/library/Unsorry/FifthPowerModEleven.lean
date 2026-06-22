import Mathlib.Tactic.IntervalCases

/-- The residue of a fifth power modulo 11 is always 0, 1, or 10. -/
theorem fifth_power_mod_eleven (n : ℕ) :
    n ^ 5 % 11 = 0 ∨ n ^ 5 % 11 = 1 ∨ n ^ 5 % 11 = 10 := by
  have h : n ^ 5 % 11 = (n % 11) ^ 5 % 11 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 11 < 11 := Nat.mod_lt _ (by decide)
  interval_cases (n % 11) <;> decide
