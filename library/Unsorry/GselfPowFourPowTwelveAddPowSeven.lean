import Mathlib

theorem gself_pow_four_pow_twelve_add_pow_seven (n : ℤ) : (n^4) ∣ (n^12 + n^7) := by
  exact ⟨n^8 + n^3, by ring⟩
