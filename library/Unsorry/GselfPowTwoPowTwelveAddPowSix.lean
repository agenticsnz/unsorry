import Mathlib

theorem gself_pow_two_pow_twelve_add_pow_six (n : ℤ) : (n^2) ∣ (n^12 + n^6) := by
  exact ⟨n^10 + n^4, by ring⟩
