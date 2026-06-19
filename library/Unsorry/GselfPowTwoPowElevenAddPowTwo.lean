import Mathlib

theorem gself_pow_two_pow_eleven_add_pow_two (n : ℤ) : (n^2) ∣ (n^11 + n^2) := by
  exact ⟨n^9 + 1, by ring⟩
