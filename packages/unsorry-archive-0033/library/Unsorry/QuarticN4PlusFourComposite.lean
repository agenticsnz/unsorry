import Mathlib

theorem quartic_n4_plus_four_composite_witness (n : ℤ) : ∃ p q : ℤ, n ^ 4 + 4 = p * q ∧ p = n ^ 2 - 2 * n + 2 ∧ q = n ^ 2 + 2 * n + 2 := by
  exact ⟨n ^ 2 - 2 * n + 2, n ^ 2 + 2 * n + 2, by ring, rfl, rfl⟩
