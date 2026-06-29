import Mathlib

theorem gself_pow_two_pow_25_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^25 + n^12) := by
  exact ⟨n^23 + n^10, by ring⟩
