import Mathlib

theorem gself_pow_two_pow_eleven_add_pow_seven (n : ℤ) : (n^2) ∣ (n^11 + n^7) := by
  exact ⟨n^9 + n^5, by ring⟩
