import Mathlib

theorem nat_eq_zero_of_descent_to_smaller (Q : ℕ → Prop) (desc : ∀ n, Q n → 0 < n → ∃ m, Q m ∧ m < n) : ∀ n, Q n → n = 0 := by
  sorry
