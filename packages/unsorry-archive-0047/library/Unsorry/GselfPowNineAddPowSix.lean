import Mathlib

theorem gself_pow_nine_add_pow_six (n : ℤ) : (n) ∣ (n^9 + n^6) := by
  exact ⟨n^8 + n^5, by ring⟩
