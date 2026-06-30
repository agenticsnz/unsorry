import Mathlib

theorem gself_pow_three_pow_eleven_add_pow_five (n : ℤ) : (n^3) ∣ (n^11 + n^5) := by
  exact ⟨n^8 + n^2, by ring⟩
