import Mathlib

theorem gself_pow_24_add_pow_six (n : ℤ) : (n) ∣ (n^24 + n^6) := by
  exact ⟨n^23 + n^5, by ring⟩
