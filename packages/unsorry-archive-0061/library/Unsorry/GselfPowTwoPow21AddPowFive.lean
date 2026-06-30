import Mathlib

theorem gself_pow_two_pow_21_add_pow_five (n : ℤ) : (n^2) ∣ (n^21 + n^5) := by
  exact ⟨n^19 + n^3, by ring⟩
