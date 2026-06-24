import Mathlib

theorem gself_pow_four_pow_twelve_add_pow_four (n : ℤ) : (n^4) ∣ (n^12 + n^4) := by
  exact ⟨n^8 + 1, by ring⟩
