import Mathlib

theorem gself_pow_three_pow_eleven_add_pow_seven (n : ℤ) : (n^3) ∣ (n^11 + n^7) := by
  exact ⟨n^8 + n^4, by ring⟩
