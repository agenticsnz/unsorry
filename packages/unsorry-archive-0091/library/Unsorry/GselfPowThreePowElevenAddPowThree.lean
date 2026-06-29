import Mathlib

theorem gself_pow_three_pow_eleven_add_pow_three (n : ℤ) : (n^3) ∣ (n^11 + n^3) := by
  exact ⟨n^8 + 1, by ring⟩
