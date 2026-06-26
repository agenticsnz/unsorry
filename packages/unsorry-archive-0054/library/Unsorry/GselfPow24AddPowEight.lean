import Mathlib

theorem gself_pow_24_add_pow_eight (n : ℤ) : (n) ∣ (n^24 + n^8) := by
  exact ⟨n^23 + n^7, by ring⟩
