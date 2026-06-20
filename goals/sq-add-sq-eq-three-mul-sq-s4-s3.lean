import Mathlib

theorem nat_measure_positive_descent_forces_zero {α : Type*} (Q : α → Prop) (m : α → Nat) (desc : ∀ a, Q a → 0 < m a → ∃ b, Q b ∧ 0 < m b ∧ m b < m a) : ∀ a, Q a → m a = 0 := by
  sorry
