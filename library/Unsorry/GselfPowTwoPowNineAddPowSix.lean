import Mathlib

theorem gself_pow_two_pow_nine_add_pow_six (n : ℤ) : (n^2) ∣ (n^9 + n^6) := by
  exact ⟨n^7 + n^4, by ring⟩
