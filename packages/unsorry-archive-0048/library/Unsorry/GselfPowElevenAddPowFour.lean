import Mathlib

theorem gself_pow_eleven_add_pow_four (n : ℤ) : (n) ∣ (n^11 + n^4) := by
  exact ⟨n^10 + n^3, by ring⟩
