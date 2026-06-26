import Mathlib

theorem gself_pow_25_add_pow_eight (n : ℤ) : (n) ∣ (n^25 + n^8) := by
  exact ⟨n^24 + n^7, by ring⟩
