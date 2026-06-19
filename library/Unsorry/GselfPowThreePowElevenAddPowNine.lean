import Mathlib

theorem gself_pow_three_pow_eleven_add_pow_nine (n : ℤ) : (n^3) ∣ (n^11 + n^9) := by
  exact ⟨n^8 + n^6, by ring⟩
