import Mathlib

theorem gself_pow_eleven_add_pow_five (n : ℤ) : (n) ∣ (n^11 + n^5) := by
  exact ⟨n^10 + n^4, by ring⟩
