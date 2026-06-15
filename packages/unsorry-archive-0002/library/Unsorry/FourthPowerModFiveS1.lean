import Mathlib.Tactic.Ring

theorem fourth_power_mod_five_reduce (n : ℕ) : n ^ 4 % 5 = (n % 5) ^ 4 % 5 := by
  rw [Nat.pow_mod]
