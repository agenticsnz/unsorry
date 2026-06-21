import Mathlib

theorem gself_pow_eleven_add_pow_seven (n : ℤ) : (n) ∣ (n^11 + n^7) := by
  exact ⟨n^10 + n^6, by ring⟩
