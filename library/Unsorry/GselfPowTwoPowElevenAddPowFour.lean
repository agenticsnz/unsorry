import Mathlib

theorem gself_pow_two_pow_eleven_add_pow_four (n : ℤ) : (n^2) ∣ (n^11 + n^4) := by
  exact ⟨n^9 + n^2, by ring⟩
