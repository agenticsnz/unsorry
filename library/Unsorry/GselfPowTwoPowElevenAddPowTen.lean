import Mathlib

theorem gself_pow_two_pow_eleven_add_pow_ten (n : ℤ) : (n^2) ∣ (n^11 + n^10) := by
  exact ⟨n^9 + n^8, by ring⟩
