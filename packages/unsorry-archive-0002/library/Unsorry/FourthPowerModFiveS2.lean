import Mathlib.Tactic.Ring

theorem fourth_power_residue_mod_five (r : ℕ) (hr0 : 1 ≤ r) (hr : r < 5) : r ^ 4 % 5 = 1 := by
  have h : r = 1 ∨ r = 2 ∨ r = 3 ∨ r = 4 := by omega
  rcases h with rfl | rfl | rfl | rfl <;> decide
