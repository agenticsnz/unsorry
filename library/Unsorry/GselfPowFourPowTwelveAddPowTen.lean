import Mathlib

theorem gself_pow_four_pow_twelve_add_pow_ten (n : ℤ) : (n^4) ∣ (n^12 + n^10) := by
  exact ⟨n^8 + n^6, by ring⟩
