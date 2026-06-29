import Mathlib

theorem gself_pow_two_pow_nine_add_pow_eight (n : ℤ) : (n^2) ∣ (n^9 + n^8) := by
  exact ⟨n^7 + n^6, by ring⟩
