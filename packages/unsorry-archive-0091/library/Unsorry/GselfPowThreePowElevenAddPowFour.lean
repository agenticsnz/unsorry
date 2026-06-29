import Mathlib

theorem gself_pow_three_pow_eleven_add_pow_four (n : ℤ) : (n^3) ∣ (n^11 + n^4) := by
  exact ⟨n^8 + n, by ring⟩
