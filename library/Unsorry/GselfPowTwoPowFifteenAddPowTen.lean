import Mathlib

theorem gself_pow_two_pow_fifteen_add_pow_ten (n : ℤ) : (n^2) ∣ (n^15 + n^10) := by
  exact ⟨n^13 + n^8, by ring⟩
