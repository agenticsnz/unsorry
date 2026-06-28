import Mathlib

theorem gself_pow_four_pow_eleven_add_pow_eight (n : ℤ) : (n^4) ∣ (n^11 + n^8) := by
  exact ⟨n^7 + n^4, by ring⟩
