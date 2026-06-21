import Mathlib

theorem gself_pow_eleven_add_pow_nine (n : ℤ) : (n) ∣ (n^11 + n^9) := by
  exact ⟨n^10 + n^8, by ring⟩
