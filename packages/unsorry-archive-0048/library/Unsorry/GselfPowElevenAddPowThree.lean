import Mathlib

theorem gself_pow_eleven_add_pow_three (n : ℤ) : (n) ∣ (n^11 + n^3) := by
  exact ⟨n^10 + n^2, by ring⟩
