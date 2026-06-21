import Mathlib

theorem gself_pow_eleven_add_pow_six (n : ℤ) : (n) ∣ (n^11 + n^6) := by
  exact ⟨n^10 + n^5, by ring⟩
