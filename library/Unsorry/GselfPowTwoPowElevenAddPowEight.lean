import Mathlib

theorem gself_pow_two_pow_eleven_add_pow_eight (n : ℤ) : (n^2) ∣ (n^11 + n^8) := by
  exact ⟨n^9 + n^6, by ring⟩
