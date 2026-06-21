import Mathlib

theorem choose_succ_succ_add (n r : ℕ) : (n + 2).choose (r + 1) = (n + 1).choose (r + 1) + (n + 1).choose r := by
  rw [Nat.choose_succ_succ (n + 1) r]
  ring