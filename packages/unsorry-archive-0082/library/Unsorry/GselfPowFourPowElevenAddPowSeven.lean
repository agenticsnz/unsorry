import Mathlib

theorem gself_pow_four_pow_eleven_add_pow_seven (n : ℤ) : (n^4) ∣ (n^11 + n^7) := by
  exact ⟨n^7 + n^3, by ring⟩
