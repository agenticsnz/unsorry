import Mathlib

theorem gself_pow_four_pow_eleven_add_pow_four (n : ℤ) : (n^4) ∣ (n^11 + n^4) := by
  exact ⟨n^7 + 1, by ring⟩
