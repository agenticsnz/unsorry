import Mathlib

theorem gself_pow_two_pow_21_add_pow_ten (n : ℤ) : (n^2) ∣ (n^21 + n^10) := by
  exact ⟨n^19 + n^8, by ring⟩
