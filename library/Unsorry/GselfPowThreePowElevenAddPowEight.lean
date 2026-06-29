import Mathlib

theorem gself_pow_three_pow_eleven_add_pow_eight (n : ℤ) : (n^3) ∣ (n^11 + n^8) := by
  exact ⟨n^8 + n^5, by ring⟩
