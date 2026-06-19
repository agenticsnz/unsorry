import Mathlib

theorem gself_pow_eleven_add_pow_eight (n : ℤ) : (n) ∣ (n^11 + n^8) := by
  exact ⟨n^10 + n^7, by ring⟩
