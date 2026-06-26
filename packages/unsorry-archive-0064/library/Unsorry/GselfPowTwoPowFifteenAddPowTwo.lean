import Mathlib

theorem gself_pow_two_pow_fifteen_add_pow_two (n : ℤ) : (n^2) ∣ (n^15 + n^2) := by
  exact ⟨n^13 + 1, by ring⟩
