import Mathlib

theorem gself_pow_four_pow_twelve_add_pow_six (n : ℤ) : (n^4) ∣ (n^12 + n^6) := by
  exact ⟨n^8 + n^2, by ring⟩
