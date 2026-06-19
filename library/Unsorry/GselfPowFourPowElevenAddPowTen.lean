import Mathlib

theorem gself_pow_four_pow_eleven_add_pow_ten (n : ℤ) : (n^4) ∣ (n^11 + n^10) := by
  exact ⟨n^7 + n^6, by ring⟩
