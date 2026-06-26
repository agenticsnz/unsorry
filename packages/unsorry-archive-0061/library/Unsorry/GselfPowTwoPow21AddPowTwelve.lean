import Mathlib

theorem gself_pow_two_pow_21_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^21 + n^12) := by
  exact ⟨n^19 + n^10, by ring⟩
